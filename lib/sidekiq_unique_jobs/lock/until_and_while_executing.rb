# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilAndWhileExecuting < BaseLock
      def execute
        return unless locked?
        unlock

        runtime_lock.execute { yield }
      end

      def runtime_lock
        @runtime_lock ||= SidekiqUniqueJobs::Lock::WhileExecuting.new(item, callback, redis_pool)
      end
    end
  end
end
