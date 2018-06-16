# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilTimeout < BaseLock
      def lock
        @locksmith.lock(@item[LOCK_TIMEOUT_KEY])
      end

      def unlock
        true
      end

      def execute(callback)
        yield if block_given?
        callback.call
      end
    end
  end
end
