require 'rubygems'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'remix/stash'

include Remix

begin
  require 'memcached'
  CCache = Memcached.new('localhost:11211')
rescue
  puts "memcached not found (skipping)"
end

begin
  require 'memcache'
  RCache = MemCache.new('localhost:11211')
rescue
  puts "memcached-client not found (skipping)"
end

stash.clear
