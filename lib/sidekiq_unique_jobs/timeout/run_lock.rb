# frozen_string_literal: true

module SidekiqUniqueJobs
  module Timeout
    class RunLock < Timeout::Calculator
      def lock_expiration
        @lock_expiration ||= @item[LOCK_EXPIRATION_KEY]
        @lock_expiration ||= worker_class_lock_expiration
        @lock_expiration ||= worker_class_run_lock_expiration
      end
    end
  end
end
