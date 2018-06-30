# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class BaseLock
      include SidekiqUniqueJobs::Logging

      def initialize(item, redis_pool = nil)
        @item       = prepare_item(item)
        @redis_pool = redis_pool
      end

      def lock
        locksmith.lock(item[LOCK_TIMEOUT_KEY])
      end

      def execute(_callback = nil)
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def unlock
        locksmith.signal(item[JID_KEY]) # Only signal to release the lock
      end

      def delete
        locksmith.delete # Soft delete (don't forcefully remove when expiration is set)
      end

      def delete!
        locksmith.delete! # Force delete the lock
      end

      def locked?
        locksmith.locked?(item[JID_KEY])
      end

      private

      attr_reader :item, :redis_pool, :operative

      def locksmith
        @locksmith ||= SidekiqUniqueJobs::Locksmith.new(item, redis_pool)
      end

      def using_protection(callback)
        @operative = true
        yield
      rescue Sidekiq::Shutdown
        @operative = false
        raise
      ensure
        unlock_and_callback(callback)
      end

      def prepare_item(item)
        calculator = SidekiqUniqueJobs::Timeout::Calculator.new(item)
        item[LOCK_TIMEOUT_KEY]    = calculator.lock_timeout
        item[LOCK_EXPIRATION_KEY] = calculator.lock_expiration
        SidekiqUniqueJobs::UniqueArgs.digest(item)
        item
      end

      def unlock_and_callback(callback)
        return notify_about_manual_unlock unless operative
        unlock

        return notify_about_manual_unlock if locked?
        callback_safely(callback)
      end

      def notify_about_manual_unlock
        log_fatal("the unique_key: #{item[UNIQUE_DIGEST_KEY]} needs to be unlocked manually")
      end

      def callback_safely(callback)
        callback.call
      rescue StandardError
        log_warn("the callback for unique_key: #{item[UNIQUE_DIGEST_KEY]} failed!")
        raise
      end
    end
  end
end
