# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecuting < BaseLock
      RUN_SUFFIX ||= ':RUN'

      def initialize(item, redis_pool = nil)
        super(item, redis_pool)
        append_unique_key_suffix
      end

      # Returning true makes sure the client
      #   can push the job on the queue
      def lock
        true
      end

      # Locks the job with the RUN_SUFFIX appended
      def execute(callback)
        locksmith.lock(item[LOCK_TIMEOUT_KEY]) do
          using_protection(callback) do
            yield if block_given?
          end
        end
      end

      private

      # This is safe as the base_lock always creates a new digest
      #   The append there for needs to be done every time
      def append_unique_key_suffix
        item[UNIQUE_DIGEST_KEY] = item[UNIQUE_DIGEST_KEY] + RUN_SUFFIX
      end
    end
  end
end
