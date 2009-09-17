module Remix; end

class Remix::Stash
  require 'remix/stash/extension'
  require 'remix/stash/cluster'
  require 'remix/stash/protocol'

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
    @opts = name == :root ? {:coherency => :action, :ttl => 0} : {}
  end

  def add(*keys)
    opts = default_opts(keys)
    value = keys.pop
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io| Protocol.add(io, key, value, opts[:ttl])}
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
    cluster(opts).select(key) {|io| Protocol.decr(io, key, step)}
  end

  def default(opts = {})
    base = @opts.merge!(opts)
    if opts.has_key? :coherency
      [:dynamic, :action, :transaction].include?(opts[:coherency]) or raise ArgumentError,
        "Invalid coherency setting used (#{opts[:coherency].inspect})"
    end
    root = @@instances[:root] || Stash.new(:root)
    self == root ?
      base :
      root.default.merge(base)
  end

  def delete(*keys)
    opts = default_opts(keys)
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io| Protocol.delete(io, key)}
  end

  def eval(*keys)
    opts = default_opts(keys)
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io|
      value = Protocol.get(io, key)
      if value
        Marshal.load(value)
      else
        value = yield(*keys)
        Protocol.set(io, key, dump_value(value), opts[:ttl])
        value
      end
    }
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
    cluster(opts).select(key) {|io| Protocol.incr(io, key, step)}
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
    cluster(opts).select(key) {|io| Protocol.set(io, key, dump_value(value), opts[:ttl])}
  end
  alias []= set

  def transaction
    yield self
  ensure
    cycle
  end

  def write(*keys)
    opts = default_opts(keys)
    value = keys.pop
    key = canonical_key(keys, opts)
    cluster(opts).select(key) {|io| Protocol.set(io, key, value, opts[:ttl])}
  end

private

  KEY_SEPARATOR = '/'
  def canonical_key(keys, opts = default_opts)
    "#{implicit_scope}#{keys.join(KEY_SEPARATOR)}#{vector(opts)}"
  end

  def cluster(opts = {})
    @@clusters[opts[:cluster] || :default]
  end

  def coherency
    default[:coherency]
  end

  def default_opts(params = {})
    params.last.is_a?(Hash) ? default.merge(params.pop) : default
  end

  def dump_value(value)
    Marshal.dump(value)
  end

  EMPTY_SCOPE = ''
  def implicit_scope
    if @scope
      scope = @scope.call(self)
      scope ? "#{scope}/" : EMPTY_SCOPE
    else
      EMPTY_SCOPE
    end
  end

  def load_value(data)
    Marshal.load(data) if data
  rescue TypeError, ArgumentError
    logger = default_opts[:logger]
    logger && logger.error("[stash] Unable to load marshal stream: #{data.inspect}")
    nil
  end

  def vector(opts)
    return if @name == :root
    return @vector if @vector && coherency != :dynamic
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

class Object; include Remix::Stash::Extension end
module Remix; extend Remix::Stash::Extension end
