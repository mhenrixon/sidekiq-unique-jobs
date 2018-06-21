# frozen_string_literal: true

module SidekiqUniqueJobs
  module Timeout
    class Calculator
      include SidekiqUniqueJobs::SidekiqWorkerMethods
      attr_reader :item

      def initialize(item)
        @item         = item
        @worker_class = item[CLASS_KEY]
      end

      def time_until_scheduled
        return 0 unless scheduled_at
        scheduled_at.to_i - Time.now.utc.to_i
      end

      def scheduled_at
        @scheduled_at ||= item[AT_KEY]
      end

      def seconds
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def lock_expiration
        @lock_expiration ||= begin
          expiration = item[LOCK_EXPIRATION_KEY]
          expiration ||= worker_options[LOCK_EXPIRATION_KEY]
          expiration && expiration + time_until_scheduled
        end
      end

      def lock_timeout
        @lock_timeout = begin
          timeout = default_worker_options[LOCK_TIMEOUT_KEY]
          timeout = default_lock_timeout if default_lock_timeout
          timeout = worker_options[LOCK_TIMEOUT_KEY] if worker_options.key?(LOCK_TIMEOUT_KEY)
          timeout
        end
      end

      def default_lock_timeout
        SidekiqUniqueJobs.config.default_lock_timeout
      end
    end
  end
end
