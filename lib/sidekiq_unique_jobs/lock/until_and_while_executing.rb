# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilAndWhileExecuting < BaseLock
      def execute(callback)
        unlock

        # TODO: Make the key for these specific to runlocks
        runtime_lock.execute(callback) do
          yield
        end
      end

      def runtime_lock
        @runtime_lock ||= SidekiqUniqueJobs::Lock::WhileExecuting.new(@item, @redis_pool)
      end
    end
  end
end
