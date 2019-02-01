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
        @item       = item
        @callback   = callback
        @redis_pool = redis_pool
        add_uniqueness_when_missing # Used to ease testing
      end

      # Handles locking of sidekiq jobs.
      #   Will call a conflict strategy if lock can't be achieved.
      # @return [String] the sidekiq job id
      def lock
        @attempt = 0
        return item[JID_KEY] if locked?

        if (token = locksmith.lock(item[LOCK_TIMEOUT_KEY]))
          token
        else
          call_strategy
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
        locksmith.unlock(item[JID_KEY]) # Only signal to release the lock
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

      def add_uniqueness_when_missing
        return if item.key?(UNIQUE_DIGEST_KEY)

        # The below should only be done to ease testing
        # in production this will be done by the middleware
        SidekiqUniqueJobs::Job.add_uniqueness(item)
      end

      def call_strategy
        @attempt += 1
        strategy.call { lock if replace? }
      end

      def replace?
        strategy.replace? && attempt < 2
      end

      # The sidekiq job hash
      # @return [Hash] the Sidekiq job hash
      attr_reader :item

      # The sidekiq redis pool
      # @return [Sidekiq::RedisConnection, ConnectionPool, NilClass] the redis connection
      attr_reader :redis_pool

      # The sidekiq job hash
      # @return [Proc] the callback to use after unlock
      attr_reader :callback

      # The current attempt to lock the job
      # @return [Integer] the numerical value of the attempt
      attr_reader :attempt

      # The interface to the locking mechanism
      # @return [SidekiqUniqueJobs::Locksmith]
      def locksmith
        @locksmith ||= SidekiqUniqueJobs::Locksmith.new(item, redis_pool)
      end

      def with_cleanup
        yield
      rescue Sidekiq::Shutdown
        log_info("Sidekiq is shutting down, the job `should` be put back on the queue. Keeping the lock!")
        raise
      else
        unlock_with_callback
      end

      def unlock_with_callback
        return log_warn("might need to be unlocked manually") unless unlock

        callback_safely
        item[JID_KEY]
      end

      def callback_safely
        callback&.call
      rescue StandardError
        log_warn("unlocked successfully but the #after_unlock callback failed!")
        raise
      end

      def strategy
        @strategy ||= OnConflict.find_strategy(item[ON_CONFLICT_KEY]).new(item)
      end
    end
  end
end
