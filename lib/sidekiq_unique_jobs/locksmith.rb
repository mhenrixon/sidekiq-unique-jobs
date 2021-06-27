# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Locksmith # rubocop:disable Metrics/ClassLength
    # includes "SidekiqUniqueJobs::Connection"
    # @!parse include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Connection

    # includes "SidekiqUniqueJobs::Logging"
    # @!parse include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Logging

    # includes "SidekiqUniqueJobs::Reflectable"
    # @!parse include SidekiqUniqueJobs::Reflectable
    include SidekiqUniqueJobs::Reflectable

    # includes "SidekiqUniqueJobs::Timing"
    # @!parse include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::Timing

    # includes "SidekiqUniqueJobs::Script::Caller"
    # @!parse include SidekiqUniqueJobs::Script::Caller
    include SidekiqUniqueJobs::Script::Caller

    # includes "SidekiqUniqueJobs::JSON"
    # @!parse include SidekiqUniqueJobs::JSON
    include SidekiqUniqueJobs::JSON

    #
    # @return [Float] used to take into consideration the inaccuracy of redis timestamps
    CLOCK_DRIFT_FACTOR = 0.01

    #
    # @!attribute [r] key
    #   @return [Key] the key used for locking
    attr_reader :key
    #
    # @!attribute [r] job_id
    #   @return [String] a sidekiq JID
    attr_reader :job_id
    #
    # @!attribute [r] config
    #   @return [LockConfig] the configuration for this lock
    attr_reader :config
    #
    # @!attribute [r] item
    #   @return [Hash] a sidekiq job hash
    attr_reader :item

    #
    # Initialize a new Locksmith instance
    #
    # @param [Hash] item a Sidekiq job hash
    # @option item [Integer] :lock_ttl the configured expiration
    # @option item [String] :jid the sidekiq job id
    # @option item [String] :unique_digest the unique digest (See: {LockDigest#lock_digest})
    # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
    #
    def initialize(item, redis_pool = nil)
      @item        = item
      @key         = Key.new(item[LOCK_DIGEST] || item[UNIQUE_DIGEST]) # fallback until can be removed
      @job_id      = item[JID]
      @config      = LockConfig.new(item)
      @redis_pool  = redis_pool
    end

    #
    # Deletes the lock unless it has a pttl set
    #
    #
    def delete
      return if config.pttl.positive?

      delete!
    end

    #
    # Deletes the lock regardless of if it has a pttl set
    #
    def delete!
      call_script(:delete, key.to_a, [job_id, config.pttl, config.type, config.limit]).positive?
    end

    #
    # Create a lock for the Sidekiq job
    #
    # @return [String] the Sidekiq job_id that was locked/queued
    #
    def lock
      redis(redis_pool) do |conn|
        lock!(conn, method(:primed_sync)) do
          return job_id
        end
      end
    end

    def execute(&block)
      raise SidekiqUniqueJobs::InvalidArgument, "#execute needs a block" unless block

      redis(redis_pool) do |conn|
        lock!(conn, method(:primed_async), &block)
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
      result = call_script(:unlock, key.to_a, argv, conn)
      reflect(:unlocked, item) if result == job_id
      result
    end

    # Checks if this instance is considered locked
    #
    # @return [true, false] true when the :LOCKED hash contains the job_id
    #
    def locked?(conn = nil)
      return taken?(conn) if conn

      redis { |rcon| taken?(rcon) }
    end

    #
    # Nicely formatted string with information about self
    #
    #
    # @return [String]
    #
    def to_s
      "Locksmith##{object_id}(digest=#{key} job_id=#{job_id} locked=#{locked?})"
    end

    #
    # @see to_s
    #
    def inspect
      to_s
    end

    #
    # Compare this locksmith with another
    #
    # @param [Locksmith] other the locksmith to compare with
    #
    # @return [true, false]
    #
    def ==(other)
      key == other.key && job_id == other.job_id
    end

    private

    attr_reader :redis_pool

    #
    # Used to reduce some duplication from the two methods
    #
    # @param [<type>] conn <description>
    # @param [<type>] primed_method <description>
    #
    # @return [<type>] <description>
    #
    # @yieldparam [<type>] x <description>
    # @yieldreturn [<type>] <describe what yield should return>
    def lock!(conn, primed_method)
      return yield job_id if locked?(conn)

      enqueue(conn) do
        primed_method.call(conn) do
          return yield job_id if job_id == call_script(:lock, key.to_a, argv, conn)
        end
      end
    end

    #
    # Prepares all the various lock data
    #
    # @param [Redis] conn a redis connection
    #
    # @return [nil] when redis was already prepared for this lock
    # @return [yield<String>] when successfully enqueued
    #
    def enqueue(conn)
      queued_token, elapsed = timed do
        call_script(:queue, key.to_a, argv, conn)
      end

      validity = config.pttl - elapsed - drift(config.pttl)

      return unless queued_token && (validity >= 0 || config.pttl.zero?)

      write_lock_info(conn)
      yield queued_token
    end

    #
    # Pops an enqueued token
    # @note Used for runtime locks to avoid problems with blocking commands
    #   in current thread
    #
    # @param [Redis] conn a redis connection
    #
    # @return [nil] when lock was not possible
    # @return [Object] whatever the block returns when lock was acquired
    #
    def primed_async(conn)
      return yield if Concurrent::Promises
                      .future(conn) { |red_con| pop_queued(red_con) }
                      .value(add_drift(config.ttl))

      reflect(:timeout, item) unless config.wait_for_lock?
    end

    #
    # Pops an enqueued token
    # @note Used for non-runtime locks
    #
    # @param [Redis] conn a redis connection
    #
    # @return [nil] when lock was not possible
    # @return [Object] whatever the block returns when lock was acquired
    #
    def primed_sync(conn)
      if (popped_jid = pop_queued(conn))
        return yield popped_jid
      end

      reflect(:timeout, item) unless config.wait_for_lock?
    end

    #
    # Does the actual popping of the enqueued token
    #
    # @param [Redis] conn a redis connection
    #
    # @return [String] a previously enqueued token (now taken off the queue)
    #
    def pop_queued(conn)
      if config.wait_for_lock?
        brpoplpush(conn)
      else
        rpoplpush(conn)
      end
    end

    #
    # @api private
    #
    def brpoplpush(conn)
      # passing timeout 0 to brpoplpush causes it to block indefinitely
      conn.brpoplpush(key.queued, key.primed, timeout: config.timeout)
    end

    #
    # @api private
    #
    def rpoplpush(conn)
      conn.rpoplpush(key.queued, key.primed)
    end

    #
    # Writes lock information to redis.
    #   The lock information contains information about worker, queue, limit etc.
    #
    #
    # @return [void]
    #
    def write_lock_info(conn)
      return unless config.lock_info?

      conn.set(key.info, lock_info)
    end

    #
    # Used to combat redis imprecision with ttl/pttl
    #
    # @param [Integer] val the value to compute drift for
    #
    # @return [Integer] a computed drift value
    #
    def drift(val)
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 millisecond, plus 1 millisecond min drift
      # for small TTLs.
      (val + 2).to_f * CLOCK_DRIFT_FACTOR
    end

    def add_drift(val)
      val + drift(val)
    end

    #
    # Checks if the lock has been taken
    #
    # @param [Redis] conn a redis connection
    #
    # @return [true, false]
    #
    def taken?(conn)
      conn.hexists(key.locked, job_id)
    end

    def argv
      [job_id, config.pttl, config.type, config.limit]
    end

    def lock_info
      @lock_info ||= dump_json(
        WORKER => item[CLASS],
        QUEUE => item[QUEUE],
        LIMIT => item[LOCK_LIMIT],
        TIMEOUT => item[LOCK_TIMEOUT],
        TTL => item[LOCK_TTL],
        TYPE => config.type,
        LOCK_ARGS => item[LOCK_ARGS],
        TIME => now_f,
      )
    end
  end
end
