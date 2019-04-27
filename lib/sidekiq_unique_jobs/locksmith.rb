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
                   keys: [key.exists, key.available, UNIQUE_SET, key.digest],
                   argv: [jid, ttl, lock_type])

      grab_lock(timeout) do |token|
        return_jid_or_block_value(&block)
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
      Scripts.call(
        :unlock,
        redis_pool,
        keys: [key.exists, key.grabbed, key.available, key.version, UNIQUE_SET, key.digest],
        argv: [jid, ttl, lock_type],
      )
    end

    # Checks if this instance is considered locked
    #
    # @return [true, false] true when the grabbed token contains the job_id
    #
    def locked?
      convert_legacy_lock
      redis(redis_pool) { |conn| conn.get(key.exists) == jid }
    end

    private

    attr_reader :key, :ttl, :jid, :redis_pool, :lock_type

    def convert_legacy_lock
      Scripts.call(
        :convert_legacy_lock,
        redis_pool,
        keys: [key.exists, key.digest],
        argv: [jid, current_time.to_f],
      )
    end

    def grab_lock(timeout = nil)
      redis(redis_pool) do |conn|
        if timeout.nil? || timeout.positive?
          # passing timeout 0 to blpop causes it to block
          _key, token = conn.brpop(key.available, timeout || 0)
        else
          token = conn.lpop(key.available)
        end

        return yield jid if token
      end
    end

    def touch_grabbed_token
      redis(redis_pool) do |conn|
        conn.hset(grabbed_key, jid, current_time.to_f)
        conn.expire(grabbed_key, ttl) if ttl && lock_type == :until_expired
      end
    end

    def return_jid_or_block_value
      return jid unless block_given?

      # The reason for begin is to only signal when we have a block
      begin
        return yield jid
      ensure
        unlock
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
