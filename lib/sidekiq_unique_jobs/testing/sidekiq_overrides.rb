require 'sidekiq/testing'

module Sidekiq
  module Worker
    module Overrides
      def self.included(base)
        base.extend ClassMethods

        base.class_eval do
          class << self
            alias_method :clear_all_orig, :clear_all
            alias_method :clear_all, :clear_all_ext
          end
        end
      end

      module ClassMethods
        def clear_all_ext
          clear_all_orig
          unique_prefix = SidekiqUniqueJobs.config.unique_prefix
          unique_keys = Sidekiq.redis { |conn| conn.keys("#{unique_prefix}*") }
          return if unique_keys.empty?

          Sidekiq.redis { |conn| conn.del(*unique_keys) }
        end
      end
    end

    include Overrides
  end
end
