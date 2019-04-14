# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs while the job is executing in the server process
    # - Locks before yielding to the worker's perform method
    # - Unlocks after yielding to the worker's perform method
    #
    # See {#lock} for more information about the client.
    # See {#execute} for more information about the server
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class WhileExecuting < BaseLock
      RUN_SUFFIX ||= ":RUN"

      # @param [Hash] item the Sidekiq job hash
      # @param [Proc] callback callback to call after unlock
      # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
      #
      def initialize(item, callback, redis_pool = nil)
        super(item, callback, redis_pool)
        append_unique_key_suffix
      end

      # Simulate that a client lock was achieved.
      #   These locks should only ever be created in the server process.
      # @return [true] always returns true
      def lock
        true
      end

      # Executes in the Sidekiq server process.
      #   These jobs are locked in the server process not from the client
      # @yield to the worker class perform method
      def execute
        return strategy.call unless locksmith.lock(item[LOCK_TIMEOUT_KEY])

        yield
      rescue Exception # rubocop:disable Lint/RescueException
        delete!
        raise
      else
        unlock_with_callback
      end

      private

      # This is safe as the base_lock always creates a new digest
      #   The append there for needs to be done every time
      def append_unique_key_suffix
        item[UNIQUE_DIGEST_KEY] = item[UNIQUE_DIGEST_KEY] + RUN_SUFFIX
      end
    end
  end
end
