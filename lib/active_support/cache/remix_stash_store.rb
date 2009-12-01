require 'remix/stash'

module ActiveSupport
  module Cache
    class RemixStashStore < Store
      
      def initialize(*servers)
        if servers.last.is_a?(Hash)
          # were passing extra settings
          stash.default(servers.pop)
        end
        Remix::Stash.define_cluster(:environment => servers)
        stash.default(:cluster => :environment)      
        @stash = Remix::Stash.new(:active_support_cache)
      end

      def read(name, options = nil)
        super
        @stash[name]
      end

      def write(name, value, options = nil)
        super
        @stash[name] = value.freeze
      end

      def delete(name, options = nil)
        super
        @stash.clear(name)
      end

      def exist?(name, options = nil)
        super
        @stash.read(name)
      end

      def clear
        @stash.clear
      end
      
    end
  end
end