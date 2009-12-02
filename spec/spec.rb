#!/usr/bin/env ruby

if __FILE__ == $0
  base = File.dirname(__FILE__)
  Dir[base + '/*_spec.rb'].each {|f| require f}
else
  require 'rubygems'
  require 'test/unit'
  require 'shoulda'

  load File.dirname(__FILE__) + '/support/rails/config/environment.rb'
  ENV['MEMCACHED_SERVERS'] = 'localhost:11211'
  ENV['MEMCACHED_NAMESPACE'] = 'spec'

  $LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
  require 'remix/stash'

  Spec = Test::Unit::TestCase

  include Remix
end