# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuted < BaseLock
      OK ||= 'OK'

      def execute
        return unless locked?
        with_cleanup { yield }
      end
    end
  end
end
