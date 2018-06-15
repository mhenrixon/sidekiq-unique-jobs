# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuting < BaseLock
      def execute(callback)
        unlock
        callback.call
        yield
      end
    end
  end
end
