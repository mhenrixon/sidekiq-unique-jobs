# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilAndWhileExecuting < BaseLock
      def execute(callback)
        unlock

        runtime_lock.execute(callback) do
          yield if block_given?
        end
      end

      def runtime_lock
        @runtime_lock ||= SidekiqUniqueJobs::Lock::WhileExecuting.new(item, redis_pool)
      end
    end
  end
end
