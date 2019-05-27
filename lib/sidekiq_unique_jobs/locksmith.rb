# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Locksmith # rubocop:disable Metrics/ClassLength
    # includes "SidekiqUniqueJobs::Connection"
    # @!parse include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Connection

    # includes "SidekiqUniqueJobs::Logging"
    # @!parse include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Logging

    # includes "SidekiqUniqueJobs::Timing"
    # @!parse include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::Timing

    # includes "SidekiqUniqueJobs::Script::Caller"
    # @!parse include SidekiqUniqueJobs::Script::Caller
    include SidekiqUniqueJobs::Script::Caller

    # includes "SidekiqUniqueJobs::JSON"
    # @!parse include SidekiqUniqueJobs::JSON
    include SidekiqUniqueJobs::JSON

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
    # @!attribute [r] type
    #   @return [Symbol] the type of lock see {SidekiqUniqueJobs.locks}
    attr_reader :type
    #
    # @!attribute [r] timeout
    #   @return [Integer, nil] the number of seconds to wait for lock
    attr_reader :timeout
    #
    # @!attribute [r] limit
    #   @return [Integer] the number of simultaneous locks
    attr_reader :limit
    #
    # @!attribute [r] ttl
    #   @return [Integer, nil] the number of seconds to keep the lock after processing
    attr_reader :ttl
    #
    # @!attribute [r] pttl
    #   @return [Integer, nil] the number of milliseconds to keep the lock after processing
    attr_reader :pttl
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
    # @option item [String] :unique_digest the unique digest (See: {UniqueArgs#unique_digest})
    # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
    #
    def initialize(item, redis_pool = nil)
      @item        = item
      @key         = Key.new(item[UNIQUE_DIGEST])
      @job_id      = item[JID]
      @timeout     = item.fetch(LOCK_TIMEOUT) { 0 }
      @type        = item[LOCK]
      @type      &&= @type.to_sym
      @redis_pool  = redis_pool
      @limit       = item[LOCK_LIMIT] || 1
      @ttl         = item.fetch(LOCK_TTL) { item.fetch(LOCK_EXPIRATION) }.to_i
      @pttl        = @ttl * 1000
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
    # @return [true, false] true when the :LOCKED hash contains the job_id
    #
    def locked?(conn = nil)
      return _locked?(conn) if conn

      redis { |rcon| _locked?(rcon) }
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
      return yield job_id if locked?(conn)

      enqueue(conn) do
        if wait_for_primed_token(conn)
          return yield job_id if call_script(:lock, key.to_a, argv, conn) == job_id
        else
          log_warn("Timed out while waiting for primed token (digest: #{key}, job_id: #{job_id})")
        end
      end
    end

    def lock_async(conn)
      return yield job_id if locked?(conn)

      enqueue(conn) do
        primed = Concurrent::Promises.future(conn) { |red_con| wait_for_primed_token(red_con) }

        if primed.value
          return yield job_id if call_script(:lock, key.to_a, argv, conn) == job_id
        else
          log_warn("Timed out after #{timeout}s while waiting for primed token (digest: #{key}, job_id: #{job_id})")
        end
      end
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

      return unless queued_token && (validity >= 0 || pttl.zero?)

      set_lock_info
      yield queued_token
    end

    def set_lock_info # rubocop:disable Metrics/MethodLength
      return unless SidekiqUniqueJobs.config.use_lock_info

      Concurrent::Promises.future do
        redis do |conn|
          conn.multi do
            conn.hmset(
              key.info,
              WORKER, item[CLASS],
              QUEUE, item[QUEUE],
              LIMIT, item[LOCK_LIMIT],
              TIMEOUT, item[LOCK_TIMEOUT],
              TTL, item[LOCK_TTL],
              TYPE, item[LOCK_TYPE],
              UNIQUE_ARGS, dump_json(item[UNIQUE_ARGS])
            )
            conn.pexpire(key.info, pttl) if type == :until_expired
          end
        end
      end
    end

    def drift(val)
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 millisecond, plus 1 millisecond min drift
      # for small TTLs.
      (val.to_i * CLOCK_DRIFT_FACTOR).to_i + 2
    end

    def _locked?(conn)
      conn.hexists(key.locked, job_id)
    end
  end
end
