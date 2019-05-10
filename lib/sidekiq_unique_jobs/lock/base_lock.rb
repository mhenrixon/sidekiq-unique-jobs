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
      def lock(&block)
        @attempt = 0
        return call_strategy unless (locked_token = locksmith.lock(&block))

        locked_token
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
        locksmith.unlock # Only signal to release the lock
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
        locksmith.locked?
      end

      #
      # The lock manager/client
      #
      # @api private
      # @return [SidekiqUniqueJobs::Locksmith] the locksmith for this sidekiq job
      #
      def locksmith
        @locksmith ||= SidekiqUniqueJobs::Locksmith.new(item, redis_pool)
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

      # @!attribute [r] item
      #   @return [Hash<String, Object>] the Sidekiq job hash
      attr_reader :item
      # @!attribute [r] redis_pool
      #   @return [Sidekiq::RedisConnection, ConnectionPool, NilClass] the redis connection
      attr_reader :redis_pool
      # @!attribute [r] callback
      #   @return [Proc] the block to call after unlock
      attr_reader :callback
      # @!attribute [r] attempt
      #   @return [Integer] the current locking attempt
      attr_reader :attempt

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
        @strategy ||= OnConflict.find_strategy(item[ON_CONFLICT_KEY]).new(item, redis_pool)
      end
    end
  end
end
