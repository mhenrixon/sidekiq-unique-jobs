# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Locksmith
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::Script::Caller

    CLOCK_DRIFT_FACTOR = 0.01

    attr_reader :key, :job_id, :type, :timeout, :limit, :ttl, :pttl

    #
    # Initialize a new Locksmith instance
    #
    # @param [Hash] item a Sidekiq job hash
    # @option item [Integer] :lock_ttl the configured expiration
    # @option item [String] :jid the sidekiq job id
    # @option item [String] :unique_digest the unique digest (See: {UniqueArgs#unique_digest})
    # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
    #
    def initialize(item, redis_pool = nil)
      @key           = Key.new(item[UNIQUE_DIGEST])
      @job_id        = item[JID]
      @timeout       = item.fetch(LOCK_TIMEOUT) { 0 }
      @type          = item[LOCK]
      @type        &&= @type.to_sym
      @redis_pool    = redis_pool
      @limit         = item[LOCK_LIMIT] || 1 # removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
      @ttl           = item.fetch(LOCK_TTL) { item.fetch(LOCK_EXPIRATION) }.to_i
      @pttl          = @ttl * 1000
    end

    #
    # Deletes the lock unless it has a pttl set
    #
    #
    def delete
      return if pttl.positive?

      delete!
    end

    #
    # Deletes the lock regardless of if it has a pttl set
    #
    def delete!
      call_script(:delete, key.to_a, [job_id]).positive?
    end

    #
    # Create a lock for the item
    #
    # @return [String] the Sidekiq job_id that was locked/queued
    #
    def lock(&block)
      redis(redis_pool) do |conn|
        return lock_async(conn, &block) if block_given?

        lock_sync(conn) do
          return job_id
        end
      end
    end

    #
    # Removes the lock keys from Redis if locked by the provided jid/token
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock(conn = nil)
      return false unless locked?(conn)

      unlock!(conn)
    end

    #
    # Removes the lock keys from Redis
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock!(conn = nil)
      call_script(:unlock, key.to_a, argv, conn)
    end

    # Checks if this instance is considered locked
    #
    # @return [true, false] true when the grabbed token contains the job_id
    #
    def locked?(conn = nil)
      call_script(:locked, key.to_a, [job_id], conn).positive?
    end

    def to_s
      "Locksmith##{object_id}(digest=#{key} job_id=#{job_id}, locked=#{locked?})"
    end

    def inspect
      to_s
    end

    def ==(other)
      key == other.key && job_id == other.job_id
    end

    private

    attr_reader :redis_pool

    def argv
      [job_id, pttl, type, limit]
    end

    def lock_sync(conn)
      enqueue(conn) do
        return unless wait_for_primed_token(conn)

        call_script(:lock, key.to_a, argv, conn)
      end
      return yield job_id if locked?(conn)
    end

    def lock_async(conn)
      return_value = nil

      future = Concurrent::Promises.future_on(:io) do
        wait_for_primed_token(conn)
      end

      enqueue(conn) do
        future.wait!
        return_value = call_script(:lock, key.to_a, argv, conn)
        return_value = yield job_id if return_value == job_id
      end

      return_value
    ensure
      unlock!(conn)
    end

    def wait_for_primed_token(conn = nil)
      primed_token, _elapsed = timed do
        if timeout.nil? || timeout.positive?
          # passing timeout 0 to brpoplpush causes it to block indefinitely
          conn.brpoplpush(key.queued, key.primed, timeout: timeout || 0)
        else
          conn.rpoplpush(key.queued, key.primed)
        end
      end

      primed_token
    end

    def enqueue(conn)
      queued_token, elapsed = timed do
        call_script(:queue, key.to_a, argv, conn)
      end

      validity = pttl.to_i - elapsed - drift(pttl)

      return yield queued_token if (validity >= 0 || pttl.zero?) && (queued_token == job_id)
    end

    def drift(val)
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 millisecond, plus 1 millisecond min drift
      # for small TTLs.
      (val.to_i * CLOCK_DRIFT_FACTOR).to_i + 2
    end
  end
end
