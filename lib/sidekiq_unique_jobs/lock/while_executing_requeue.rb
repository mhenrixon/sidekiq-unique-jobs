# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecutingRequeue < WhileExecuting
      def lock
        true
      end

      def execute
        locksmith.lock(item[LOCK_TIMEOUT_KEY], raise: true) do
          yield if block_given?
        end

        unlock

        Sidekiq::Client.push(item) unless locksmith.locked?
      end
    end
  end
end
