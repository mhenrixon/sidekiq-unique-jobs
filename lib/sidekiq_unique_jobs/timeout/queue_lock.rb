# frozen_string_literal: true

module SidekiqUniqueJobs
  module Timeout
    class QueueLock < Timeout::Calculator
      def lock_expiration
        @lock_expiration ||= worker_class_lock_expiration
        @lock_expiration ||= worker_class_queue_lock_expiration
        @lock_expiration ||= SidekiqUniqueJobs.config.default_queue_lock_expiration
        @lock_expiration = @item[LOCK_EXPIRATION_KEY] if @item.key?(LOCK_EXPIRATION_KEY)
        @lock_expiration.to_i + time_until_scheduled if @lock_expiration
      end
    end
  end
end
