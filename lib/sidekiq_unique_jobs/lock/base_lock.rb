# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class BaseLock
      def initialize(item, redis_pool = nil)
        @calculator = SidekiqUniqueJobs::Timeout::QueueLock.new(item)
        @item       = prepare_item(item, @calculator)
        @redis_pool = redis_pool
        @locksmith  = SidekiqUniqueJobs::Locksmith.new(@item, @redis_pool)
      end

      def lock
        @locksmith.lock(@calculator.lock_timeout)
      end

      def execute(_callback = nil)
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def unlock
        @locksmith.unlock
        @locksmith.delete!
      end

      private

      def prepare_item(item, calculator)
        item[LOCK_TIMEOUT_KEY] = calculator.lock_timeout
        item[LOCK_EXPIRATION_KEY] = calculator.lock_expiration
        SidekiqUniqueJobs::UniqueArgs.digest(item)
        item
      end
    end
  end
end
