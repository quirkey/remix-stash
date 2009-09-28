if defined?(Rails)
  stash.default(:logger => Rails.logger)

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
    stash.default(:cluster => :environment)
  end

  if namespace = ENV['MEMCACHED_NAMESPACE']
    stash.default(:namespace => namespace)
  end

end
