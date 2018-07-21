# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecutingReject < WhileExecuting
      def execute
        return strategy.call unless locksmith.lock(item[LOCK_TIMEOUT_KEY])

        with_cleanup { yield }
      end

      def strategy
        @strategy ||= OnConflict.find_strategy(:reject).new(item)
      end
    end
  end
end
