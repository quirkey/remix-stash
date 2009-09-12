$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require 'remix/stash'

require 'rubygems'
require 'memcached'
require 'memcache'

CCache = Memcached.new('localhost:11211')
RCache = MemCache.new('localhost:11211')

stash.clear
