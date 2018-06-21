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

      def append_unique_key_suffix
        digest = item[UNIQUE_DIGEST_KEY]
        return digest if digest.end_with?(RUN_SUFFIX)
        [digest, RUN_SUFFIX].join('')
      end
    end
  end
end
