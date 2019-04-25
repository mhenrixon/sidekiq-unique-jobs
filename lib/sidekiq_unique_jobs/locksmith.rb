# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Locksmith
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Logging

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
      # @concurrency   = 1 # removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
      @ttl           = item[LOCK_EXPIRATION_KEY]
      @jid           = item[JID_KEY]
      @key           = SidekiqUniqueJobs::Key.new(item[UNIQUE_DIGEST_KEY])
      @lock_type     = item[LOCK_KEY]
      @lock_type   &&= @lock_type.to_sym
      @redis_pool    = redis_pool
    end

    #
    # Deletes the lock unless it has a ttl set
    #
    #
    def delete
      return if ttl

      delete!
    end

    #
    # Deletes the lock regardless of if it has a ttl set
    #
    def delete!
      Scripts.call(
        :delete,
        redis_pool,
        keys: [key.exists, key.grabbed, key.available, key.version, UNIQUE_SET, key.digest],
      )
    end

    #
    # Create a lock for the item
    #
    # @param [Integer] timeout the number of seconds to wait for a lock.
    #
    # @return [String] the Sidekiq job_id (jid)
    #
    def lock(timeout = nil, &block)
      Scripts.call(:lock, redis_pool,
                   keys: [key.exists, key.grabbed, key.available, UNIQUE_SET, key.digest],
                   argv: [jid, ttl, lock_type])

      grab_token(timeout) do |token|
        touch_grabbed_token(token)
        return_token_or_block_value(token, &block)
      end
    end
    alias wait lock

    #
    # Removes the lock keys from Redis if locked by the provided jid/token
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock(token = nil)
      token ||= jid
      return false unless locked?(token)

      unlock!(token)
    end

    #
    # Removes the lock keys from Redis
    #
    # @param [String] token the token to unlock (defaults to jid)
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock!(token = nil)
      token ||= jid

      Scripts.call(
        :unlock,
        redis_pool,
        keys: [key.exists, key.grabbed, key.available, key.version, UNIQUE_SET, key.digest],
        argv: [token, ttl, lock_type],
      )
    end

    # Checks if this instance is considered locked
    #
    # @param [String] token sidekiq job_id
    #
    # @return [true, false] true when the grabbed token contains the job_id
    #
    def locked?(token = nil)
      token ||= jid

      convert_legacy_lock(token)
      redis(redis_pool) { |conn| conn.hexists(key.grabbed, token) }
    end

    private

    attr_reader :key, :ttl, :jid, :redis_pool, :lock_type

    def convert_legacy_lock(token)
      Scripts.call(
        :convert_legacy_lock,
        redis_pool,
        keys: [key.grabbed, key.digest],
        argv: [token, current_time.to_f],
      )
    end

    def grab_token(timeout = nil)
      redis(redis_pool) do |conn|
        if timeout.nil? || timeout.positive?
          log_debug("BLPOP :AVAILABLE")
          # passing timeout 0 to blpop causes it to block
          _key, token = conn.blpop(key.available, timeout || 0)
        else
          log_debug("LPOP :AVAILABLE")
          token = conn.lpop(key.available)
        end

        log_debug("Got token #{token} yielding it")

        return yield token if token
      end
    end

    def touch_grabbed_token(token)
      redis(redis_pool) do |conn|
        log_debug("Setting :GRABBED to #{token}")
        conn.hset(key.grabbed, token, current_time.to_f)
        conn.expire(key.grabbed, ttl) if ttl && lock_type == :until_expired
      end
    end

    def return_token_or_block_value(token)
      return token unless block_given?

      # The reason for begin is to only signal when we have a block
      begin
        log_debug("yielding #{token}")
        yield token
      ensure
        unlock(token)
      end
    end

    def current_time
      seconds, microseconds_with_frac = redis_time
      Time.at(seconds, microseconds_with_frac)
    end

    def redis_time
      redis(&:time)
    end
  end
end
