# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class RescheduleWhileExecuting < BaseLock
      def lock
        true
      end

      def execute(callback)
        @locksmith.lock(@item[LOCK_TIMEOUT_KEY]) do
          yield
          callback.call
        end

        Sidekiq::Client.push(@item) unless @locksmith.locked?
      end
    end
  end
end
