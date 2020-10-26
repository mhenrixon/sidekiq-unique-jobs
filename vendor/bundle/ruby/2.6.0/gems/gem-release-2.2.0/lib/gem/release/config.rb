require 'gem/release/config/env'
require 'gem/release/config/files'
require 'gem/release/helper/hash'

module Gem
  module Release
    class Config
      include Helper::Hash

      attr_reader :opts

      SOURCES = [Env, Files]

      def initialize
        @opts = load
      end

      def [](key)
        opts[key]
      end

      def for(key)
        common.merge(self[key] || {})
      end

      def common
        opts.reject { |_, value| value.is_a?(Hash) }
      end

      private

        def load
          opts = sources.map(&:load)
          opts.inject { |one, other| deep_merge(one, other) }
        end

        def sources
          SOURCES.map(&:new)
        end
    end
  end
end
