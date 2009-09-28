#!/usr/bin/env ruby

if __FILE__ == $0
  base = File.dirname(__FILE__)
  Dir[base + '/*_spec.rb'].each {|f| require f}
else
  require 'rubygems'
  require 'test/unit'
  require 'shoulda'

  $LOAD_PATH << File.dirname(__FILE__) + '/../lib'
  require 'remix/stash'

  Spec = Test::Unit::TestCase

  include Remix
end