# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuting < BaseLock
      def execute
        unlock_with_callback
        yield
      end
    end
  end
end
