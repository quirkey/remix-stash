require File.dirname(__FILE__) + '/spec'
require 'active_support/cache/remix_stash_store'

class ActiveSupportCacheSpec < Spec

  context "ActiveSupport::Cache" do    
    context "looking up the cache store" do
      setup do
        @cache = ActiveSupport::Cache.lookup_store(:remix_stash_store, 'localhost:11211', :some_opt => 'namespace')  
      end
      
      should "return a remix stash store" do
        assert @cache.is_a?(ActiveSupport::Cache::RemixStashStore)
      end
      
      should "set default options passed as a hash" do
        assert_equal 'namespace', Remix::Stash.new(:active_support_cache).default[:some_opt]
      end
    end
    
    context "with a cache" do
      setup do
        @cache = ActiveSupport::Cache.lookup_store(:remix_stash_store, 'localhost:11211')
        @stash = Remix::Stash.new(:active_support_cache)
      end
      
      teardown do
        @stash.clear
      end
      
      should "write key" do
        @cache.write('foo', 'bar')
        assert_equal 'bar', @stash['foo']
      end
      
      should "read key" do
        @stash['foo'] = 'bar'
        assert_equal 'bar', @cache.read('foo')
      end
      
      should "delete key" do
        @stash['foo'] = 'bar'
        assert_equal 'bar', @cache.read('foo')
        @cache.delete('foo')
        assert_nil @cache.read('foo')
      end
      
      should "return true if key exists" do
        @stash['foo'] = 'bar'
        assert @cache.exist?('foo')
      end
      
      should "return false if key does not exist" do
        assert !@cache.exist?('foo')
      end
      
      should "clear all keys" do
        @stash['foo'] = 'bar'
        assert_equal 'bar', @cache.read('foo')
        @cache.clear
        assert !@cache.exist?('foo')
      end
      
    end
    
  end


end