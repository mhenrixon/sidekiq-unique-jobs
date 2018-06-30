# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuted < BaseLock
      OK ||= 'OK'

      def execute
        return unless locked?
        with_cleanup { yield if block_given? }
      end
    end
  end
end
