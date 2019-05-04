# frozen_string_literal: true

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
      @jid           = item[JID_KEY]
      @ttl           = item[LOCK_EXPIRATION_KEY].to_i * 1000
      @timeout       = item[LOCK_TIMEOUT_KEY]
      @type          = item[LOCK_KEY]
      @type        &&= @type.to_sym
      @redis_pool    = redis_pool
      @limit         = item[LOCK_LIMIT_KEY] || 1 # removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
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

      delete! > 0
    end

    #
    # Deletes the lock regardless of if it has a ttl set
    #
    def delete!
      call_script(:delete, key.to_a, [jid, current_time])
    end

    #
    # Create a lock for the item
    #
    # @return [String] the Sidekiq job_id that was locked/queued
    #
    def lock
      queued_token = enqueue_lock
      log_debug("#{__method__} queued_token: #{queued_token}")
      return unless queued_token == jid

      obtain(queued_token) do |locked_token|
        if block_given?
          begin
            return yield locked_token if locked_token == jid
          ensure
            unlock
          end
        end

        locked_token if locked_token == jid
      end
    end
    alias wait lock

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
      call_script(:unlock, key.to_a, [jid, ttl, type, current_time, limit])
    end

    # Checks if this instance is considered locked
    #
    # @return [true, false] true when the grabbed token contains the job_id
    #
    def locked?
      call_script(:locked, key.to_a, [jid]) > 0
    end

    def to_s
      "Locksmith(digest=#{key} job_id=#{jid})"
    end

    def inspect
      to_s
    end

    def ==(other)
      key == other.key && jid == other.jid
    end

    def <=>(other)
      key <=> other.key && jid <=> other.jid
    end

    private

    attr_reader :key, :ttl, :jid, :redis_pool, :type, :timeout, :limit

    def enqueue_lock
      locked_jid, time_elapsed = timed do
        call_script(:queue, key.to_a, [jid, ttl, type, current_time, limit])
      end

      validity = ttl.to_i - time_elapsed - drift

      return unless locked_jid == jid
      return unless validity >= 0 || ttl.zero?

      locked_jid
    end

    def obtain(queued_token)
      log_debug("#{__method__} queued_token: #{queued_token}")
      return yield jid if locked?

      return unless (primed_token = pop_token)
      log_debug("#{__method__} primed_token: #{primed_token}")

      locked_token = call_script(:lock, key.to_a, [jid, primed_token, ttl, type, current_time, limit])
      log_debug("#{__method__} locked_token: #{locked_token}")

      return yield locked_token if locked_token
    end

    def pop_token
      return jid if locked?
      primed_token, elapsed = timed do
        redis do |conn|
          if timeout.nil? || timeout.positive?
            # passing timeout 0 to brpoplpush causes it to block indefinitely
            conn.brpoplpush(key.queued, key.primed, timeout || 0)
          else
            conn.rpoplpush(key.queued, key.primed)
          end
        end
      end

      # TODO: Collect metrics and stats
      log_debug("Waited #{elapsed}ms for #{primed_token} to be released (digest: #{key.digest}, job_id: #{jid})")
      primed_token
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

    def drift
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 millisecond, plus 1 millisecond min drift
      # for small TTLs.
      (ttl * CLOCK_DRIFT_FACTOR).to_i + 2
    end
  end
end
