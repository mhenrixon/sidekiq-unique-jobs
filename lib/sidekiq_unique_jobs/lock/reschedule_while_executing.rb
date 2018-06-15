# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class RescheduleWhileExecuting < BaseLock
      def lock
        true
      end

      def execute(callback = nil)
        @locksmith.lock do
          yield
          callback.call
        end

        Sidekiq::Client.push(@item) unless @locksmith.locked?
      end

      def unlock
        @locksmith.unlock
      end
    end
  end
end
