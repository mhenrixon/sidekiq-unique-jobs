# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecuting < BaseLock
      RUN_SUFFIX ||= ':RUN'
      def initialize(item, redis_pool = nil)
        super
        item[UNIQUE_DIGEST_KEY] = append_unique_key_suffix
      end

      def lock
        true
      end

      def execute(callback)
        locksmith.lock(item[LOCK_TIMEOUT_KEY]) do
          yield if block_given?
          callback&.call
        end
      end

      def unlock
        true
      end

      private

      # This is safe as the base_lock always creates a new digest
      #   The append there for needs to be done every time
      def append_unique_key_suffix
        [item[UNIQUE_DIGEST_KEY], RUN_SUFFIX].join('')
      end
    end
  end
end
