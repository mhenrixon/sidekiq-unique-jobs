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
        # Write the token to the job hash so that we can later release this specific token
        token = locksmith.lock(item[LOCK_TIMEOUT_KEY])
        item[LOCK_TOKEN_KEY] = token if token
      end

      def execute(_callback = nil)
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      def unlock
        locksmith.signal(item[LOCK_TOKEN_KEY]) # Only signal to release the lock
      end

      def delete
        locksmith.delete # Soft delete (don't forcefully remove when expiration is set)
      end

      def locked?
        locksmith.locked?
      end

      private

      attr_reader :item, :locksmith, :redis_pool, :operative

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
        delete

        return notify_about_manual_unlock if locked?
        callback_safely(callback)
      end

      def callback_and_unlock(callback)
        return notify_about_manual_unlock unless operative
        callback_safely(callback)

        unlock
        delete
        notify_about_manual_unlock if locked?
      end

      def notify_about_manual_unlock
        log_fatal("the unique_key: #{item[UNIQUE_DIGEST_KEY]} needs to be unlocked manually")
      end

      def callback_safely(callback)
        callback.call
      rescue StandardError => exception
        log_warn("the callback for unique_key: #{item[UNIQUE_DIGEST_KEY]} failed!")
        log_error(exception)
        raise
      end
    end
  end
end
