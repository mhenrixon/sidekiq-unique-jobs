# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Abstract base class for locks
    #
    # @abstract
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class BaseLock
      include SidekiqUniqueJobs::Logging

      # @param [Hash] item the Sidekiq job hash
      # @param [Proc] callback the callback to use after unlock
      # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
      def initialize(item, callback, redis_pool = nil)
        @item       = prepare_item(item)
        @callback   = callback
        @redis_pool = redis_pool
      end

      # Handles locking of sidekiq jobs.
      #   Will call a conflict strategy if lock can't be achieved.
      # @return [String] the sidekiq job id
      def lock
        if (token = locksmith.lock(item[LOCK_TIMEOUT_KEY]))
          token
        else
          strategy.call
        end
      end

      # Execute the job in the Sidekiq server processor
      # @raise [NotImplementedError] needs to be implemented in child class
      def execute
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      # Unlocks the job from redis
      # @return [String] sidekiq job id when successful
      # @return [false] when unsuccessful
      def unlock
        locksmith.signal(item[JID_KEY]) # Only signal to release the lock
      end

      # Deletes the job from redis if it is locked.
      def delete
        locksmith.delete # Soft delete (don't forcefully remove when expiration is set)
      end

      # Forcefully deletes the job from redis.
      #   This is good for jobs when a previous lock was not unlocked
      def delete!
        locksmith.delete! # Force delete the lock
      end

      # Checks if the item has achieved a lock
      # @return [true] when this jid has locked the job
      # @return [false] when this jid has not locked the job
      def locked?
        locksmith.locked?(item[JID_KEY])
      end

      private

      # The sidekiq job hash
      # @return [Hash] the Sidekiq job hash
      attr_reader :item

      # The sidekiq redis pool
      # @return [Sidekiq::RedisConnection, ConnectionPool, NilClass] the redis connection
      attr_reader :redis_pool

      # The sidekiq job hash
      # @return [Proc] the callback to use after unlock
      attr_reader :callback

      # The interface to the locking mechanism
      # @return [SidekiqUniqueJobs::Locksmith]
      def locksmith
        @locksmith ||= SidekiqUniqueJobs::Locksmith.new(item, redis_pool)
      end

      def with_cleanup
        yield
      rescue Sidekiq::Shutdown
        notify_about_manual_unlock
        raise
      else
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
        return notify_about_manual_unlock unless unlock

        callback_safely
        item[JID_KEY]
      end

      def callback_safely
        callback&.call
      rescue StandardError
        log_warn("The unique_key: #{item[UNIQUE_DIGEST_KEY]} has been unlocked but the #after_unlock callback failed!")
        raise
      end

      def strategy
        @strategy ||= OnConflict.find_strategy(item[ON_CONFLICT_KEY]).new(item)
      end
    end
  end
end
