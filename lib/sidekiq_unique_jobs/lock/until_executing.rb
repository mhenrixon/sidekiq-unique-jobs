# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuting < BaseLock
      def execute
        unlock_with_callback
        yield if block_given?
      end
    end
  end
end
