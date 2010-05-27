require 'remix/stash'

module ActiveSupport
  module Cache
    class RemixStashStore < Store
      include Remix
      
      def initialize(*servers)
        name = :active_support_cache
        if servers.last.is_a?(Hash)
          # were passing extra settings
          opts = servers.pop
          name = opts.delete(:name) if opts[:name]
          stash.default(opts)
        end
        Remix::Stash.define_cluster(:environment => servers)
        stash(name).default(:cluster => :environment)      
        @stash = stash(name)
      end

      def read(name, options = nil)
        super
        options ||= {}
        @stash.get(name, options)
      end

      def write(name, value, options = nil)
        super
        options ||= {}
        @stash.set(name, value.freeze, options)
      end

      def delete(name, options = nil)
        super
        options ||= {}
        @stash.clear(name, options)
      end

      def exist?(name, options = nil)
        super
        options ||= {}
        @stash.read(name, options)
      end

      def clear
        @stash.clear
      end
      
    end
  end
end