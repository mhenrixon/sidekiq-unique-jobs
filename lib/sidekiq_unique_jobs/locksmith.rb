# frozen_string_literal: true

module SidekiqUniqueJobs
  class Locksmith # rubocop:disable ClassLength
    API_VERSION = '1'
    EXISTS_TOKEN = '1'
    EXPIRES_IN = 10

    include SidekiqUniqueJobs::Connection

    def initialize(item, redis_pool = nil)
      @concurrency          = item[LOCK_CONCURRENCY_KEY] || 1
      @digest               = item[UNIQUE_DIGEST_KEY]
      @expiration           = item[LOCK_EXPIRATION_KEY]
      @jid                  = item[JID_KEY]
      @redis_pool           = redis_pool
      @stale_client_timeout = item[STALE_CLIENT_TIMEOUT_KEY]
      @tokens               = []
    end

    def create
      Scripts.call(
        :create,
        redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key],
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
      return unless expiration.nil?
      delete!
    end

    def delete!
      Scripts.call(
        :delete,
        redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key],
      )
    end

    def lock(timeout = nil, &block)
      create
      release_stale_locks

      grab_token(timeout) do |token|
        touch_grabbed_token(token)
        return_token_or_block_value(token, &block)
      end
    end
    alias wait lock

    def unlock
      return false unless locked?
      signal(tokens.pop)
    end

    def locked?(token = nil)
      if token
        redis(redis_pool) { |conn| conn.hexists(grabbed_key, token) }
      else
        tokens.each do |my_token|
          return true if locked?(my_token)
        end

        false
      end
    end

    def signal(token = jid)
      token ||= generate_unique_token

      Scripts.call(
        :signal,
        redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key],
        argv: [token, expiration],
      )
    end

    def release_stale_locks
      return unless check_staleness?

      if redis_version_greater_than_or_equal_to?('3.2')
        release_stale_locks_lua
      else
        release_stale_locks_ruby
      end
    end
    alias release release_stale_locks

    private

    attr_reader :concurrency, :digest, :expiration, :jid, :redis_pool, :stale_client_timeout, :tokens

    def redis_version_greater_than_or_equal_to?(allowed_version)
      Gem::Version.new(SidekiqUniqueJobs.redis_version) >= Gem::Version.new(allowed_version)
    end

    def grab_token(timeout = nil)
      redis(redis_pool) do |conn|
        if timeout.nil? || timeout.positive?
          # passing timeout 0 to blpop causes it to block
          _key, token = conn.blpop(available_key, timeout || 0)
        else
          token = conn.lpop(available_key)
        end

        yield token if token == jid
      end
    end

    def touch_grabbed_token(token)
      tokens.push(token)
      redis(redis_pool) { |conn| conn.hset(grabbed_key, token, current_time.to_f) }
    end

    def return_token_or_block_value(token)
      return token unless block_given?

      begin
        yield token
      ensure
        signal(token)
      end
    end

    def release_stale_locks_lua
      Scripts.call(
        :release_stale_locks,
        redis_pool,
        keys:  [exists_key, grabbed_key, available_key, release_key],
        argv: [EXPIRES_IN, @stale_client_timeout, expiration],
      )
    end

    def release_stale_locks_ruby
      redis(redis_pool) do |conn|
        create_expiring_mutex(conn) do
          release_grabbed_tokens(conn)
        end
      end
    end

    def create_expiring_mutex(conn)
      cached_current_time = current_time.to_f
      my_lock_expires_at  = cached_current_time + EXPIRES_IN + 1

      return yield conn if conn.setnx(release_key, my_lock_expires_at)

      other_lock_expires_at = conn.get(release_key).to_f

      if other_lock_expires_at < cached_current_time
        old_expires_at = conn.getset(release_key, my_lock_expires_at).to_f
        yield conn if old_expires_at == other_lock_expires_at
      end
    ensure
      conn.del(release_key) if my_lock_expires_at > (current_time.to_f - 1)
    end

    def release_grabbed_tokens(conn)
      conn.hgetall(grabbed_key).each do |token, locked_at|
        timed_out_at = locked_at.to_f + @stale_client_timeout
        signal(token) if timed_out_at < current_time.to_f
      end
    end

    def check_staleness?
      !@stale_client_timeout.nil?
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

    def release_key
      @release_key ||= namespaced_key('RELEASE')
    end

    def version_key
      @version_key ||= namespaced_key('VERSION')
    end

    def namespaced_key(variable)
      "#{digest}:#{variable}"
    end

    def current_time
      seconds, microseconds_with_frac = redis_time
      Time.at(seconds, microseconds_with_frac)
    end

    def redis_time
      redis(&:time)
    end

    def all_tokens
      redis(redis_pool) do |conn|
        conn.multi do
          conn.lrange(available_key, 0, -1)
          conn.hkeys(grabbed_key)
        end.flatten
      end
    end

    def generate_unique_token
      tokens = all_tokens
      token = Random.rand.to_s
      token = Random.rand.to_s while tokens.include? token
      token
    end
  end
end

require 'sidekiq_unique_jobs/lock/base_lock'
require 'sidekiq_unique_jobs/lock/until_executed'
require 'sidekiq_unique_jobs/lock/until_executing'
require 'sidekiq_unique_jobs/lock/until_expired'
require 'sidekiq_unique_jobs/lock/while_executing'
require 'sidekiq_unique_jobs/lock/while_executing_reject'
require 'sidekiq_unique_jobs/lock/while_executing_requeue'
require 'sidekiq_unique_jobs/lock/until_and_while_executing'
