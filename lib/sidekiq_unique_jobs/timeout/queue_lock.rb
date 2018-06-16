# frozen_string_literal: true

module SidekiqUniqueJobs
  module Timeout
    class QueueLock < Timeout::Calculator
      def lock_expiration
        @lock_expiration ||= worker_class_lock_expiration
        @lock_expiration ||= worker_class_queue_lock_expiration
        @lock_expiration ||= worker_class_run_lock_expiration
        @lock_expiration = @item[LOCK_EXPIRATION_KEY] if @item.key?(LOCK_EXPIRATION_KEY)
        @lock_expiration &&= @lock_expiration + time_until_scheduled
      end
    end
  end
end
