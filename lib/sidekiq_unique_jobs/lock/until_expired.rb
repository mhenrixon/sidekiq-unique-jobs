# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExpired < BaseLock
      def unlock
        true
      end

      def execute
        return unless locked?
        yield if block_given?
        # this lock does not handle after_unlock since we don't know when that would
      end
    end
  end
end
