if defined?(Rails)
  require 'active_support/cache/remix_stash_store'
  
  Remix::Stash::Runtime.logger = Rails.logger

  module Remix::Stash::RailsSupport
  private

    def cycle_action_vectors
      Remix::Stash.cycle_action
    end

  end

  class ActionController::Base
    include Remix::Stash::RailsSupport
    after_filter :cycle_action_vectors
  end

  if servers = ENV['MEMCACHED_SERVERS']
    Remix::Stash.define_cluster(:environment => servers.split(','))
    Remix.stash.default(:cluster => :environment)
  end

  if namespace = ENV['MEMCACHED_NAMESPACE']
    Remix.stash.default(:namespace => namespace)
  end

end

unless Remix::Stash::Runtime.logger
  require 'logger'
  Remix::Stash::Runtime.logger = Logger.new(STDERR)
end
