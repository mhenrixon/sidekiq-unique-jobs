# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExpired < BaseLock
      def unlock
        true
      end

      def execute(callback)
        return unless locked?
        yield if block_given?
        callback.call
      end
    end
  end
end
