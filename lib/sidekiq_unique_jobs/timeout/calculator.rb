# frozen_string_literal: true

module SidekiqUniqueJobs
  module Timeout
    class Calculator
      def initialize(item)
        @item = item
      end

      def time_until_scheduled
        return 0 unless @item[AT_KEY]
        @item[AT_KEY].to_i - Time.now.utc.to_i
      end

      def seconds
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def lock_timeout
        @lock_timeout ||= @item[LOCK_TIMEOUT_KEY]
        @lock_timeout ||= worker_class_lock_timeout
        @lock_timeout ||= SidekiqUniqueJobs.config.default_lock_timeout
      end

      def worker_class_lock_timeout
        worker_class_lock_expiration_for(LOCK_TIMEOUT_KEY)
      end

      def worker_class_queue_lock_expiration
        worker_class_lock_expiration_for(QUEUE_LOCK_EXPIRATION_KEY)
      end

      def worker_class_run_lock_expiration
        worker_class_lock_expiration_for(RUN_LOCK_EXPIRATION_KEY)
      end

      def worker_class_lock_expiration
        worker_class_lock_expiration_for(LOCK_EXPIRATION_KEY)
      end

      def worker_class
        @worker_class ||= SidekiqUniqueJobs.worker_class_constantize(@item[CLASS_KEY])
      end

      def worker_class_lock_expiration_for(key)
        return unless worker_class.respond_to?(:get_sidekiq_options)
        worker_class.get_sidekiq_options[key]
      end
    end
  end
end
