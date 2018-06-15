# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecuting < BaseLock
      def lock
        true
      end

      # TODO: Make the key for these specific to runlocks
      def execute(callback)
        @locksmith.lock(@calculator.lock_timeout) do
          yield
          callback&.call
        end
      end

      def unlock
        true
      end
    end
  end
end
