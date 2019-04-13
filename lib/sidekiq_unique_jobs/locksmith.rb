# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  # rubocop:disable ClassLength
  class Locksmith
    include SidekiqUniqueJobs::Connection

    # @param [Hash] item a Sidekiq job hash
    # @option item [Integer] :lock_expiration the configured expiration
    # @option item [String] :jid the sidekiq job id
    # @option item [String] :unique_digest the unique digest (See: {UniqueArgs#unique_digest})
    # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
    def initialize(item, redis_pool = nil)
      # @concurrency   = 1 # removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
      @ttl           = item[LOCK_EXPIRATION_KEY]
      @jid           = item[JID_KEY]
      @unique_digest = item[UNIQUE_DIGEST_KEY]
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

    # Deletes the lock regardless of if it has a ttl set
    def delete!
      Scripts.call(
        :delete,
        redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key, UNIQUE_SET, unique_digest],
      )
    end

    #
    # Create a lock for the item
    #
    # @param [Integer] timeout the number of seconds to wait for a lock.
    #
    # @return [String] the Sidekiq job_id (jid)
    #
    #
    def lock(timeout = nil, &block)
      Scripts.call(:lock, redis_pool,
                   keys: [exists_key, grabbed_key, available_key, UNIQUE_SET, unique_digest],
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
        keys: [exists_key, grabbed_key, available_key, version_key, UNIQUE_SET, unique_digest],
        argv: [token, ttl, lock_type],
      )
    end

    #
    # @param [String] token the unique token to check for a lock.
    #   nil will default to the jid provided in the initializer
    # @return [true, false]
    #
    # Checks if this instance is considered locked
    #
    # @param [<type>] token <description>
    #
    # @return [<type>] <description>
    #
    def locked?(token = nil)
      token ||= jid

      convert_legacy_lock(token)
      redis(redis_pool) { |conn| conn.hexists(grabbed_key, token) }
    end

    private

    attr_reader :unique_digest, :ttl, :jid, :redis_pool, :lock_type

    def convert_legacy_lock(token)
      Scripts.call(
        :convert_legacy_lock,
        redis_pool,
        keys: [grabbed_key, unique_digest],
        argv: [token, current_time.to_f],
      )
    end

    def grab_token(timeout = nil)
      redis(redis_pool) do |conn|
        if timeout.nil? || timeout.positive?
          # passing timeout 0 to blpop causes it to block
          _key, token = conn.blpop(available_key, timeout || 0)
        else
          token = conn.lpop(available_key)
        end

        return yield jid if token
      end
    end

    def touch_grabbed_token(token)
      redis(redis_pool) do |conn|
        conn.hset(grabbed_key, token, current_time.to_f)
        conn.expire(grabbed_key, ttl) if ttl && lock_type == :until_expired
      end
    end

    def return_token_or_block_value(token)
      return token unless block_given?

      # The reason for begin is to only signal when we have a block
      begin
        yield token
      ensure
        unlock(token)
      end
    end

    def available_key
      @available_key ||= namespaced_key("AVAILABLE")
    end

    def exists_key
      @exists_key ||= namespaced_key("EXISTS")
    end

    def grabbed_key
      @grabbed_key ||= namespaced_key("GRABBED")
    end

    def version_key
      @version_key ||= namespaced_key("VERSION")
    end

    def namespaced_key(variable)
      "#{unique_digest}:#{variable}"
    end

    def current_time
      seconds, microseconds_with_frac = redis_time
      Time.at(seconds, microseconds_with_frac)
    end

    def redis_time
      redis(&:time)
    end
  end
  # rubocop:enable ClassLength
end
