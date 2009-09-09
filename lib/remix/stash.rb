class Stash
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
      @@clusters[k] = Cluster.new(v)
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
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.add(io, key, value, opts[:ttl])}
  end

  def clear(*keys)
    if keys.empty?
      if @name == :root
        cluster.each {|io| Protocol.flush(io)}
      else
        vk = vector_key
        cluster.select(vk) {|io|
          unless Protocol.incr(io, vk, 1)
            Protocol.add(io, vk, '0')
            Protocol.incr(io, vk, 1)
          end
        }
      end
      cycle
    else
      # remove a specific key
      key = canonical_key(keys)
      cluster.select(key) {|io| Protocol.delete(io, key)}
    end
  end

  def clear_scope
    @scope = nil
  end

  def cycle
    @vector = nil
  end

  def decr(*keys)
    step = keys.pop
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.decr(io, key, step)}
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
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.delete(io, key)}
  end

  def eval(*keys)
    opts = default_opts(keys)
    key = canonical_key(keys)
    cluster.select(key) {|io|
      value = Protocol.get_value(io, key)
      unless value
        value = yield(*keys)
        Protocol.set_value(io, key, value, opts[:ttl])
      end
      value
    }
  end

  def gate(*keys)
    key = canonical_key(keys)
    cluster.select(key) {|io|
      if Protocol.get(io, key)
        yield(*keys)
        true
      else
        false
      end
    }
  end

  def get(*keys)
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.get_value(io, key)}
  end
  alias [] get

  def incr(*keys)
    step = keys.pop
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.incr(io, key, step)}
  end

  def read(*keys)
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.get(io, key)}
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
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.set_value(io, key, value, opts[:ttl])}
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
    key = canonical_key(keys)
    cluster.select(key) {|io| Protocol.set(io, key, value, opts[:ttl])}
  end

private

  KEY_SEPARATOR = '/'
  def canonical_key(keys)
    "#{implicit_scope}#{keys.join(KEY_SEPARATOR)}#{vector}"
  end

  def cluster
    @@clusters[:default]
  end

  def coherency
    default[:coherency]
  end

  def default_opts(params)
    params.last.is_a?(Hash) ? default.merge(params.pop) : default
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

  def vector
    return 'static' if @name == :root
    return @vector.to_s if @vector && coherency != :dynamic
    vk = vector_key
    cluster.select(vk) do |io|
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

class Object; include Stash::Extension end
