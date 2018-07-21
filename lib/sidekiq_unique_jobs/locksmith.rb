# frozen_string_literal: true

module SidekiqUniqueJobs
  class Locksmith # rubocop:disable ClassLength
    API_VERSION = '1'
    EXPIRES_IN = 10

    include SidekiqUniqueJobs::Connection

    def initialize(item, redis_pool = nil)
      @concurrency   = 1 # removed in a0cff5bc42edbe7190d6ede7e7f845074d2d7af6
      @expiration    = item[LOCK_EXPIRATION_KEY]
      @jid           = item[JID_KEY]
      @unique_digest = item[UNIQUE_DIGEST_KEY]
      @redis_pool    = redis_pool
    end

    def create
      Scripts.call(
        :create,
        redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key, unique_digest],
        argv: [jid, expiration, API_VERSION, concurrency],
      )
    end

    def exists?
      redis(redis_pool) { |conn| conn.exists(exists_key) }
    end

    def available_count
      return concurrency unless exists?

      redis(redis_pool) { |conn| conn.llen(available_key) }
    end

    def delete
      return if expiration
      delete!
    end

    def delete!
      Scripts.call(
        :delete,
        redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key, unique_digest],
      )
    end

    def lock(timeout = nil, &block)
      create

      grab_token(timeout) do |token|
        touch_grabbed_token(token)
        return_token_or_block_value(token, &block)
      end
    end
    alias wait lock

    def unlock
      return false unless locked?
      signal(jid)
    end

    def locked?(token = nil)
      token ||= jid
      redis(redis_pool) { |conn| conn.hexists(grabbed_key, token) }
    end

    def signal(token = nil)
      token ||= jid

      Scripts.call(
        :signal,
        redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key, unique_digest],
        argv: [token, expiration],
      )
    end

    private

    attr_reader :concurrency, :unique_digest, :expiration, :jid, :redis_pool

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
      redis(redis_pool) { |conn| conn.hset(grabbed_key, token, current_time.to_f) }
    end

    def return_token_or_block_value(token)
      return token unless block_given?

      # The reason for begin is to only signal when we have a block
      begin
        yield token
      ensure
        signal(token)
      end
    end

    def available_key
      @available_key ||= namespaced_key('AVAILABLE')
    end

    def exists_key
      @exists_key ||= namespaced_key('EXISTS')
    end

    def grabbed_key
      @grabbed_key ||= namespaced_key('GRABBED')
    end

    def version_key
      @version_key ||= namespaced_key('VERSION')
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
end
