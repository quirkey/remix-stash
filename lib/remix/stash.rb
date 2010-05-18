module Remix; end

class Remix::Stash
  VERSION = '1.1.5'
  
  require 'remix/stash/runtime'
  require 'remix/stash/extension'
  require 'remix/stash/cluster'
  require 'remix/stash/protocol'

  include Runtime

  attr_accessor :name

  @@instances = {}
  @@clusters = {:default => Cluster.new(%w[localhost:11211])}

  def self.cluster(name)
    @@clusters[name]
  end

  def self.cycle_action
    @@instances.each {|name, stash|
      stash.cycle if stash.default[:coherency] == :action}
  end

  def self.define_cluster(clusters)
    clusters.each do |k,v|
      @@clusters[k] = Cluster === v ? v : Cluster.new(v)
    end
  end

  def self.new(name)
    @@instances[name] ||= super
  end

  def initialize(name)
    @name = name
    @scope = nil
    if name == :root
      @local = @opts = {:coherency => :action, :ttl => 0, :cluster => :default}
    else
      @local = {}
      @opts = Remix.stash.default.dup
    end
  end

  def clear(*keys)
    opts = default_opts(keys)
    if keys.empty?
      if @name == :root
        cluster(opts).each {|io| Protocol.flush(io)}
      else
        vk = vector_key
        cluster(opts).select(vk) {|io|
          unless Protocol.incr(io, vk, 1)
            Protocol.add(io, vk, '0')
            Protocol.incr(io, vk, 1)
          end
        }
      end
      cycle
    else
      # remove a specific key
      key = canonical_key(keys, opts)
      cluster(opts).select(key) {|io| Protocol.delete(io, key)}
    end
  end

  def clear_scope
    @scope = nil
  end

  def cycle
    @vector = nil
  end

  def decr(*keys)
    opts = default_opts(keys)
    step = keys.pop
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io| Protocol.decr(io, key, step, opts[:default], opts[:ttl])}
  end

  def default(opts = nil)
    if opts
      if opts.has_key? :coherency
        [:dynamic, :action, :transaction].include?(opts[:coherency]) or raise ArgumentError,
          "Invalid coherency setting used (#{opts[:coherency].inspect})"
      end
      @local.merge!(opts)
      @opts.merge!(opts)
      if @name == :root
        @@instances.each do |name, stash|
          stash.update_options unless name == :root
        end
      end
    end
    @opts
  end

  def eval(*keys)
    opts = default_opts(keys)
    key = canonical_key(keys, opts)
    activated = false
    value = nil
    cluster(opts).select(key) {|io|
      value = Protocol.get(io, key)
      if value
        value = load_value(value)
        activated = true
      else
        value = yield(*keys)
        activated = true
        Protocol.set(io, key, dump_value(value), opts[:ttl])
      end
    }
    activated ? value : yield(*keys)
  end

  def gate(*keys)
    opts = default_opts(keys)
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io|
      if Protocol.get(io, key)
        yield(*keys)
        true
      else
        false
      end
    }
  end

  def get(*keys)
    opts = default_opts(keys)
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io| load_value(Protocol.get(io, key))}
  end
  alias [] get

  def incr(*keys)
    opts = default_opts(keys)
    step = keys.pop
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io| Protocol.incr(io, key, step, opts[:default], opts[:ttl])}
  end

  def ping(name = default[:cluster])
    cluster(:cluster => name).map {|io| Protocol.ping(io)}
  end

  def read(*keys)
    opts = default_opts(keys)
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io| Protocol.get(io, key)}
  end

  def release
    @@instances.delete(@name)
  end

  def scope(&b)
    @scope = b
    self
  end

  def set(*keys)
    opts = default_opts(keys)
    value = keys.pop
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io|
      case opts[:op]
      when :add
        Protocol.add(io, key, dump_value(value), opts[:ttl])
      when :replace
        Protocol.replace(io, key, dump_value(value), opts[:ttl])
      else
        Protocol.set(io, key, dump_value(value), opts[:ttl])
      end
    }
  end
  alias []= set

  def stats(name = default[:cluster])
    cluster(:cluster => name).map do |io|
      stats = {:settings => {}, :slabs => [], :foo => {}}
      Protocol.stat(io) {|key, value|
        stats[key.to_sym] = normalize_stat(value)
      }
      Protocol.stat(io, 'settings') {|key, value|
        stats[:settings][key.to_sym] = normalize_stat(value)
      }
      prefix = stats[:settings][:stat_key_prefix]
      Protocol.stat(io, 'items') {|key, value|
        part, slab_index, subkey = *key.split(prefix)
        slab_index = slab_index.to_i
        stats[:slabs][slab_index] ||= {:index => slab_index}
        stats[:slabs][slab_index][subkey.to_sym] = normalize_stat(value)
      }
      Protocol.stat(io, 'slabs') {|key, value|
        parts = key.split(prefix)
        if parts.size == 1
          stats["slabs_#{key}".to_sym] = normalize_stat(value)
        else
          slab_index, subkey = parts.values_at(-2, -1)
          slab_index = slab_index.to_i
          stats[:slabs][slab_index] ||= {:index => slab_index}
          stats[:slabs][slab_index][subkey.to_sym] = normalize_stat(value)
        end
      }
      stats[:slabs].compact!
      stats
    end
  end

  def transaction
    yield self
  ensure
    cycle
  end

  def write(*keys)
    opts = default_opts(keys)
    value = keys.pop
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io|
      case opts[:op]
      when :add
        Protocol.add(io, key, value, opts[:ttl])
      when :replace
        Protocol.replace(io, key, value, opts[:ttl])
      when :append
        Protocol.append(io, key, value)
      when :prepend
        Protocol.prepend(io, key, value)
      else
        Protocol.set(io, key, value, opts[:ttl])
      end
    }
  end

protected

  def update_options
    @opts = stash.default.merge(@local)
  end

private

  KEY_SEPARATOR = '/'
  def canonical_key(keys, opts)
    v = vector(opts)
    namespace = opts[:namespace].to_s
    key = namespace +
      if @scope
        "#{implicit_scope}#{keys.join(KEY_SEPARATOR)}#{vector(opts)}"
      elsif v
        keys.join(KEY_SEPARATOR) << v
      else
        keys.join(KEY_SEPARATOR)
      end
    key.size > 250 ? Digest::MD5.hexdigest(key) : key
  end

  def cluster(opts = {})
    @@clusters[opts[:cluster]]
  end

  def default_opts(params)
    params.last.is_a?(Hash) ? default.merge(params.pop) : default
  end

  def dump_value(value)
    Marshal.dump(value)
  end

  def implicit_scope
    @scope.call(self) if @scope
  end

  def load_value(data)
    Marshal.load(data) if data
  rescue TypeError, NameError, ArgumentError => e
    if e.message =~ /undefined class\/module (.*)/
      retry if begin
        $1.split('::').inject(Object) {|m,x|
          m.const_get(x)}
      rescue Exception
      end
    end
    logger.error("[stash] Unable to load marshal stream: #{data.inspect}")
    nil
  end

  def normalize_stat(value)
    value == "NULL" ? nil : (Integer(value) rescue Float(value)) rescue value
  end

  def vector(opts)
    return if @name == :root
    return @vector if @vector && opts[:coherency] != :dynamic
    vk = vector_key
    cluster(opts).select(vk) do |io|
      @vector = Protocol.get(io, vk)
      unless @vector
        Protocol.add(io, vk, '0')
        @vector = Protocol.get(io, vk)
      end
      @vector = "@#@name:#@vector"
    end
  end

  def vector_key
    "#@name#{implicit_scope}_vector"
  end

  class ProtocolError < RuntimeError; end
  class ClusterError < RuntimeError; end

end

module Remix
  extend Remix::Stash::Extension
  include Remix::Stash::Extension
end

require 'remix/stash/auto_detection'
