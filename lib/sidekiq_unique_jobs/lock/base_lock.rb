# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class BaseLock
      include SidekiqUniqueJobs::Logging

      def initialize(item, redis_pool = nil)
        @item       = prepare_item(item)
        @redis_pool = redis_pool
        @locksmith  = SidekiqUniqueJobs::Locksmith.new(@item, @redis_pool)
      end

      def lock
        locksmith.lock(item[LOCK_TIMEOUT_KEY])
      end

      def execute(_callback = nil)
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def unlock
        locksmith.unlock
      end

      def delete
        locksmith.delete
      end

      def locked?
        locksmith.locked?
      end

      private

      attr_reader :item, :locksmith, :redis_pool

      def prepare_item(item)
        calculator = SidekiqUniqueJobs::Timeout::Calculator.new(item)
        item[LOCK_TIMEOUT_KEY]    = calculator.lock_timeout
        item[LOCK_EXPIRATION_KEY] = calculator.lock_expiration
        SidekiqUniqueJobs::UniqueArgs.digest(item)
        item
      end
    end
  end
end
