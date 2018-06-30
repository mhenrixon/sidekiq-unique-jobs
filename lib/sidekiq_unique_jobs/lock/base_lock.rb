# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class BaseLock
      include SidekiqUniqueJobs::Logging

      def initialize(item, callback, redis_pool = nil)
        @item       = prepare_item(item)
        @callback   = callback
        @redis_pool = redis_pool
        @operative  = true
      end

      def lock
        locksmith.lock(item[LOCK_TIMEOUT_KEY])
      end

      def execute
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def unlock
        return notify_about_manual_unlock unless operative
        locksmith.signal(item[JID_KEY]) # Only signal to release the lock
      end

      def delete
        return notify_about_manual_unlock unless operative
        locksmith.delete # Soft delete (don't forcefully remove when expiration is set)
      end

      def delete!
        return notify_about_manual_unlock unless operative
        locksmith.delete! # Force delete the lock
      end

      def locked?
        locksmith.locked?(item[JID_KEY])
      end

      private

      attr_reader :item, :redis_pool, :operative, :callback

      def locksmith
        @locksmith ||= SidekiqUniqueJobs::Locksmith.new(item, redis_pool)
      end

      def with_cleanup
        yield
      rescue Sidekiq::Shutdown
        @operative = false
        raise
      ensure
        unlock_with_callback
      end

      def prepare_item(item)
        calculator = SidekiqUniqueJobs::Timeout::Calculator.new(item)
        item[LOCK_TIMEOUT_KEY]    = calculator.lock_timeout
        item[LOCK_EXPIRATION_KEY] = calculator.lock_expiration
        SidekiqUniqueJobs::UniqueArgs.digest(item)
        item
      end

      def notify_about_manual_unlock
        log_fatal("the unique_key: #{item[UNIQUE_DIGEST_KEY]} needs to be unlocked manually")
        false
      end

      def unlock_with_callback
        token = unlock
        return notify_about_manual_unlock unless token
        callback_safely

        token
      end

      def callback_safely
        callback&.call
      rescue StandardError
        log_warn("The lock for #{item[UNIQUE_DIGEST_KEY]} has been released but the #after_unlock callback failed!")
        raise
      end
    end
  end
end
