# frozen_string_literal: true

require "concurrent/future"

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Locksmith
    include Comparable
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::Script::Caller

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
      @key           = Key.new(item[UNIQUE_DIGEST_KEY])
      @job_id        = item[JID_KEY]
      @pttl          = item[LOCK_EXPIRATION_KEY].to_i * 1000
      @timeout       = item.fetch(LOCK_TIMEOUT_KEY) { 0 }
      @type          = item[LOCK_KEY]
      @type        &&= @type.to_sym
      @redis_pool    = redis_pool
      @limit         = item[LOCK_LIMIT_KEY] || 1 # removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
    end

    #
    # Deletes the lock unless it has a pttl set
    #
    #
    def delete
      return if pttl.positive?

      delete! > 0
    end

    #
    # Deletes the lock regardless of if it has a pttl set
    #
    def delete!
      call_script(:delete, key.to_a, [job_id])
    end

    #
    # Create a lock for the item
    #
    # @return [String] the Sidekiq job_id that was locked/queued
    #
    def lock
      log_debug("Entered Locksmith##{__method__}")
      redis(redis_pool) do |conn|
        lock_async(conn) do
          unless block_given?
            log_debug("Returning from Locksmith##{__method__}")
            return job_id
          end

          begin
            log_debug("Yielding from Locksmith##{__method__}")
            return yield job_id
          ensure
            unlock!(conn)
          end
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
      log_debug("Entered Locksmith##{__method__}")
      call_script(:unlock, key.to_a, [job_id, pttl, type, limit], conn)
    end

    # Checks if this instance is considered locked
    #
    # @return [true, false] true when the grabbed token contains the job_id
    #
    def locked?(conn = nil)
      check_if_locked(conn)
    end

    # def to_s
    #   "Locksmith##{object_id}(digest=#{key} job_id=#{job_id})"
    # end

    def inspect
      to_s
    end

    def ==(other)
      key == other.key && job_id == other.job_id
    end

    def <=>(other)
      key <=> other.key && job_id <=> other.job_id
    end

    private

    attr_reader :key, :pttl, :job_id, :redis_pool, :type, :timeout, :limit

    def lock_async(conn)
      log_debug("Entered Locksmith##{__method__}")

      future = Concurrent::Future.execute(executor: :fast) do
        wait_for_primed_token(conn)
      end
      enqueue(conn) do
        future.wait
        call_script(:lock, key.to_a, [job_id, pttl, type, limit], conn)
      end

      yield if locked?(conn)
    end

    def check_if_locked(conn = nil)
      log_debug("Entered Locksmith##{__method__}")
      call_script(:locked, key.to_a, [job_id], conn) > 0
    end

    def wait_for_primed_token(conn = nil)
      log_debug("Entered Locksmith##{__method__}")

      primed_token, elapsed = timed do
        if timeout.nil? || timeout.positive?
          # passing timeout 0 to brpoplpush causes it to block indefinitely
          conn.brpoplpush(key.queued, key.primed, timeout || 0)
        else
          conn.rpoplpush(key.queued, key.primed)
        end
      end

      # TODO: Collect metrics and stats
      log_debug("Waited #{elapsed}ms for #{primed_token} to be released (digest: #{key.digest}, job_id: #{job_id})")
      primed_token
    end

    def obtain(conn = nil)

    end

    def enqueue(conn)
      log_debug("Entered Locksmith##{__method__}")

      queued_token, elapsed = timed do
        call_script(:queue, key.to_a, [job_id, pttl, type, limit], conn)
      end

      validity = pttl.to_i - elapsed - drift(pttl)

      return yield queued_token if validity >= 0 || pttl.zero?

      log_debug("Locksmith##{__method__} - Not valid anymore (queued_token: #{queued_token}, job_id: #{job_id})")
      nil
    end

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

    def drift(val)
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 millisecond, plus 1 millisecond min drift
      # for small TTLs.
      (val.to_i * CLOCK_DRIFT_FACTOR).to_i + 2
    end
  end
end
