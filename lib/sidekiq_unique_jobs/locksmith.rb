# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  # rubocop:disable Metrics/ClassLength
  class Locksmith
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Timing

    DEFAULT_REDIS_TIMEOUT = 0.1
    DEFAULT_RETRY_COUNT   = 3
    DEFAULT_RETRY_DELAY   = 200
    DEFAULT_RETRY_JITTER  = 50
    CLOCK_DRIFT_FACTOR    = 0.01

    #
    # Initialize a new Locksmith instance
    #
    # @param [Hash] item a Sidekiq job hash
    # @option item [Integer] :lock_expiration the configured expiration
    # @option item [String] :jid the sidekiq job id
    # @option item [String] :unique_digest the unique digest (See: {UniqueArgs#unique_digest})
    # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
    #
    def initialize(item, redis_pool = nil)
      # @concurrency = 1 # removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
      @jid           = item[JID_KEY]
      @key           = Key.new(item[UNIQUE_DIGEST_KEY])
      @ttl           = item[LOCK_EXPIRATION_KEY].to_i * 1000
      @lock_timeout  = item[LOCK_TIMEOUT_KEY]
      @lock_type     = item[LOCK_KEY]
      @lock_type   &&= @lock_type.to_sym
      @redis_pool    = redis_pool
      @retry_count   = item[LOCK_RETRY_COUNT_KEY] || DEFAULT_RETRY_COUNT
      @retry_delay   = item[LOCK_RETRY_DELAY_KEY] || DEFAULT_RETRY_DELAY
      @retry_jitter  = item[LOCK_RETRY_JITTER_KEY] || DEFAULT_RETRY_JITTER
      @extend        = item["lock_extend"]
      @extend_owned  = item["lock_extend_owned"]
    end

    #
    # Deletes the lock unless it has a ttl set
    #
    #
    def delete
      return if ttl.positive?

      delete!
    end

    #
    # Deletes the lock regardless of if it has a ttl set
    #
    def delete!
      Scripts.call(
        :delete,
        redis_pool,
        keys: key.to_a,
      )
    end

    #
    # Create a lock for the item
    #
    # @return [String] the Sidekiq job_id that was locked/queued
    #
    def lock
      locked_jid = if lock_timeout
        create_lock
      else
        try_lock
      end

      return yield if locked_jid && block_given?

      locked_jid
    end
    alias wait lock

    def execute
      raise ArgumentError, "#execute needs a block" unless block_given?

      grabbed_jid = grab_lock
      return yield grabbed_jid if grabbed_jid == locked_jid
    end

    #
    # Removes the lock keys from Redis if locked by the provided jid/token
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock
      return false unless locked?

      unlock!
    end

    #
    # Removes the lock keys from Redis
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock!
      Scripts.call(
        :unlock,
        redis_pool,
        keys: key.to_a,
        argv: [jid, ttl, lock_type],
      )
    end

    # Checks if this instance is considered locked
    #
    # @return [true, false] true when the grabbed token contains the job_id
    #
    def locked?
      Scripts.call(
        :locked,
        redis_pool,
        keys: [key.digest],
        argv: [jid],
      ) >= 1
    end

    private

    attr_reader :key, :ttl, :jid, :redis_pool, :lock_type, :lock_timeout

    def try_lock
      tries = @extend ? 1 : (@retry_count + 1)

      tries.times do |attempt_number|
        # Wait a random delay before retrying.
        sleep(sleepy_time) if attempt_number.positive?
        locked = create_lock
        return locked if locked
      end

      false
    end

    def sleepy_time
      (@retry_delay + rand(@retry_jitter)).to_f / 1000
    end

    def create_lock
      locked_jid, time_elapsed = timed do
        Scripts.call(:lock, redis_pool,
                     keys: key.to_a,
                     argv: [jid, ttl, lock_type, current_time])
      end

      # validity = ttl.to_i - time_elapsed - drift

      return false unless locked_jid == jid # && (validity >= 0 || ttl.zero?)

      locked_jid
    end

    def grab_lock
      redis(redis_pool) do |conn|
        if lock_timeout.nil? || lock_timeout.positive?
          conn.bzpopmin(key.wait, key.work, lock_timeout || 0)
        else
          conn.multi do
            conn.zadd(key.work, conn.zpopmin(key.wait))
          end
        end
      end
    end

    def enqueue_lock(grabbed_jid)
      redis(redis_pool) do |conn|
        conn.multi do
          conn.lpush(key.wait, grabbed_jid)
          conn.pexpire(key.wait, 5)
        end
      end
    end

    def drift
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 millisecond, plus 1 millisecond min drift
      # for small TTLs.
      (ttl * CLOCK_DRIFT_FACTOR).to_i + 2
    end
  end
  # rubocop:enable Metrics/ClassLength
end
