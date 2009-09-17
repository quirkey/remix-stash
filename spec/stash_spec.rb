require File.dirname(__FILE__) + '/spec'

class StashSpec < Spec

  def setup
    stash.clear
    Stash.class_eval("@@instances.clear")
  end

  context 'coherency' do

    should 'only allow valid coherency settings' do
      stash.default(:coherency => :action)
      stash.default(:coherency => :dynamic)
      stash.default(:coherency => :transaction)
      assert_raises ArgumentError do
        stash.default(:coherency => :other)
      end
    end

    should 'support :action coherency' do
      one = stash(:one).release
      two = stash(:one)
      two.default(:coherency => :action)
      one[:value] = 42
      assert_equal 42, two[:value]
      one.clear
      one[:value] = 43
      assert_equal 42, two[:value]
      Stash.cycle_action
      assert_equal 43, two[:value]
    end

    should 'support :dynamic coherency' do
      one = stash(:one).release
      two = stash(:one)
      two.default(:coherency => :dynamic)
      one[:value] = 42
      assert_equal 42, two[:value]
      one.clear
      one[:value] = 43
      assert_equal 43, two[:value]
    end

    should 'support :explicit coherency' do
      one = stash(:one).release
      two = stash(:one)
      two.default(:coherency => :transaction)
      one[:value] = 42
      assert_equal 42, two[:value]
      one.clear
      one[:value] = 43
      assert_equal 42, two[:value]
      Stash.cycle_action
      assert_equal 42, two[:value]
      two.cycle
      assert_equal 43, two[:value]
    end

  end

  context 'defaults' do

    should 'default to :action coherency' do
      assert_equal :action, stash.default[:coherency]
    end

    should 'use a default cluster on localhost:11211' do
      local = Stash.cluster(:default)
      assert_equal [['localhost:11211', 'localhost', 11211]], local.hosts
    end

  end

  context '.cycle_action' do

    setup do
      @cycle = stash(:action).release
      @stash = stash(:action)
      @stash.default(:coherency => :action)
    end

    should 'cycle all action conherent scopes' do
      @stash.set('a', 42)
      @cycle.clear
      assert_equal 42, @stash.get('a')
      Stash.cycle_action
      assert_nil @stash.get('a')
    end

  end

  context '.define_cluster' do

    should 'setup a cluster using an array of host/port pairs' do
      Stash.define_cluster(:simple => %w[one:1 two:2], :sample => %w[miro.local:11211])
      assert Stash.cluster(:simple)
      assert Stash.cluster(:sample)
    end

    should 'default to port 11211' do
      Stash.define_cluster(:default_port => 'default')
      assert_equal [['default', 'default', 11211]], Stash.cluster(:default_port).hosts
    end

    should 'allow Cluster object to be passed in' do
      cluster = Stash::Cluster.new(%w[localhost:11211])
      Stash.define_cluster(:object => cluster)
      assert_equal cluster, Stash.cluster(:object)
    end

  end

  context '#add' do

    should 'allow keys to be set with new values' do
      assert stash.add('f', '42')
      assert_equal '42', stash.read('f')
    end

    should 'not overwrite existing values' do
      stash['f'] = '43'
      assert !stash.add('f', '42')
      assert_equal '43', stash['f']
    end

  end

  context '#clear' do

    setup do
      stash(:a).default(:coherency => :dynamic)
    end

    should 'flush all when called without keys on root' do
      stash(:a).set(:b, :c)
      stash.set(:d, :e)
      stash.clear
      assert_nil stash(:a).get(:b)
      assert_nil stash.get(:d)
    end

    should 'clear just a scope when called without keys on a non-root node' do
      stash(:a).set(:b, :c)
      stash.set(:d, :e)
      stash(:a).clear
      assert_nil stash(:a).get(:b)
      assert_equal :e, stash.get(:d)
    end

    should 'clear just a key when called with keys on any node' do
      stash(:a).set(:b, :c)
      stash.set(:d, :e)
      stash.clear(:d)
      assert_equal :c, stash(:a).get(:b)
      assert_nil stash.get(:d)
      stash(:a).clear
      assert_nil stash(:a).get(:b)
    end

  end

  context '#clear_scope' do

    should 'remove the prior scope' do
      stash[:foo] = :bar
      stash.scope {42}
      stash[:foo] = :qux
      stash.clear_scope
      assert_equal :bar, stash[:foo]
    end

  end

  context '#cycle' do

    should 'clear the cached vector' do
      one = stash(:one).release
      two = stash(:one)
      one[:a] = :b
      assert_equal :b, two[:a]
      one.clear
      one[:a] = :c
      two.cycle
      assert_equal :c, two[:a]
    end

  end

  context '#decr' do

    should 'decrement numeric values by a positive integer' do
      stash.write(:a, '10')
      stash.decr(:a, 1)
      assert_equal 9, stash.read(:a).to_i
      stash.decr(:a, 3)
      assert_equal 6, stash.read(:a).to_i
    end

    should 'return the new numeric value' do
      stash.write(:a, '45')
      assert_equal 42, stash.decr(:a, 3)
    end

  end

  context '#default' do

    should 'return a Hash of default options' do
      assert_kind_of Hash, stash(:one).default
    end

    should 'allow setting default options' do
      s = stash(:two)
      long_time = 5000
      s.default(:ttl => long_time)
      assert_equal long_time, s.default[:ttl]
    end

    should 'merge with top-level default options' do
      s = stash(:three)
      stash.default(:ttl => 3600)
      assert_equal 3600, s.default[:ttl]
      s.default(:ttl => 4800)
      assert_equal 4800, s.default[:ttl]
      assert_equal 3600, stash.default[:ttl]
    end

  end

  context '#delete' do

    should 'remove a key from the cache' do
      stash[:foo] = 42
      stash.delete(:foo)
      assert_nil stash[:foo]
    end

    should 'return true when deleted' do
      stash[:foo] = 42
      assert stash.delete(:foo)
    end

    should 'return false when not found' do
      assert !stash.delete(:foo)
    end

  end

  context '#eval' do

    should 'evaluate the block on a cache miss' do
      ran = false
      stash.eval(:a) {ran = true}
      assert ran
    end

    should 'not evaluate on a cache hit' do
      ran = false
      stash[:a] = 42
      stash.eval(:a) {ran = false}
      assert !ran
    end

    should 'pass keys in as optional block arguments' do
      assert 42, stash.eval(42) {|a| a}
    end

  end

  context '#gate' do

    should 'not evaluate on a key miss' do
      ran = false
      stash.gate(:k) {ran = true}
      assert !ran
    end

    should 'evaluate on a key hit' do
      ran = false
      stash[:k] = :hit
      stash.gate(:k) {ran = true}
      assert ran
    end

    should 'return true on hit' do
      stash[:k] = :hit
      assert stash.gate(:k) {}
    end

    should 'return false on miss' do
      assert !stash.gate(:k) {}
    end

    should 'pass keys in as optional block arguments' do
      key = nil
      stash[42] = true
      stash.gate(42) {|k| key = k}
      assert_equal 42, key
    end

  end

  context '#get' do

    should 'allow simple get on the same keyspace as eval' do
      stash.eval(:foo) {42}
      assert_equal 42, stash[:foo]
    end

  end

  context '#incr' do

    should 'increment numeric values by the passed integer' do
      stash.write(:a, '10')
      assert_equal 12, stash.incr(:a, 2)
    end

    should 'return nil if it failed to increment' do
      assert_nil stash.incr(:a, 3)
    end

  end

  context '#read' do

    should 'read raw strings from the cache' do
      stash[:a] = 42
      assert_equal Marshal.dump(42), stash.read(:a)
    end

    should 'return nil when the key is not found' do
      assert_nil stash.read(:not_found)
    end

  end

  context '#release' do

    should 'return itself' do
      assert_instance_of Stash, stash(:one).release
    end

    should 'remove it from the name registery' do
      assert_not_equal stash(:one).release, stash(:one)
    end

  end

  context '#scope' do

    should 'set an implicit scope variable for keyspaces' do
      a = 1
      stash.scope {a}
      stash[:k] = :v
      a = 2
      assert_nil stash[:k]
    end

    should 'be used by the vector key' do
      one = stash(:one).release
      two = stash(:one)
      a = 0
      one.scope {a}
      one[:a] = 1
      two.clear
      one.cycle
      assert_equal 1, one[:a]
    end

    should 'return self' do
      assert_equal stash, stash.scope {}
    end

  end

  context '#set' do

    should 'allow simple set on the same keyspace as eval' do
      stash.set(:a, 42)
      assert_equal 42, stash.eval(:a) {fail 'expected cache hit'}
    end

  end

  context '#transaction' do

    should 'cycle the vector at the end of the transaction block' do
      one = stash(:one).release
      two = stash(:one)
      one.transaction do
        one[:a] = 42
        two.clear
        assert_equal 42, one[:a]
      end
      assert_nil one[:a]
    end

  end

  context '#write' do

    should 'write raw strings to the cache' do
      stash.write(42, '42')
      assert_equal '42', stash.read(42)
    end

  end

end
