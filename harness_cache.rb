require 'rubygems'
require 'memcache'

Cache = MemCache.new(%[localhost:11211])
Cache.flush_all