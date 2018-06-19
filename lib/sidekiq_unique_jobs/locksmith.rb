# frozen_string_literal: true

module SidekiqUniqueJobs
  class Locksmith # rubocop:disable ClassLength
    API_VERSION = '1'
    EXISTS_TOKEN = '1'
    EXPIRES_IN = 10

    def initialize(item, redis_pool = nil)
      @item                 = item
      @current_jid          = @item[JID_KEY]
      @unique_digest        = @item[UNIQUE_DIGEST_KEY]
      @redis_pool           = redis_pool
      @lock_concurrency     = @item[LOCK_CONCURRENCY_KEY] || 1
      @lock_expiration      = @item[LOCK_EXPIRATION_KEY]
      @lock_timeout         = @item[LOCK_TIMEOUT_KEY]
      @stale_client_timeout = @item[STALE_CLIENT_TIMEOUT_KEY]
      @tokens               = []
    end

    def create
      Scripts.call(
        :create,
        @redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key],
        argv: [EXISTS_TOKEN, @lock_expiration, API_VERSION, @lock_concurrency],
      )
    end

    def exists?
      redis { |conn| conn.exists(exists_key) }
    end

    def available_count
      return @lock_concurrency unless exists?

      redis { |conn| conn.llen(available_key) }
    end

    def delete!
      Scripts.call(
        :delete,
        @redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key],
      )
    end

    def lock(timeout = nil) # rubocop:disable MethodLength
      create
      release_stale_locks

      get_token(timeout) do |current_token, conn|
        return false if current_token.nil?

        @tokens.push(current_token)
        conn.hset(grabbed_key, current_token, current_time.to_f)
        return_value = current_token

        if block_given?
          begin
            return_value = yield current_token
          ensure
            signal(current_token)
          end
        end

        return_value
      end
    end
    alias wait lock

    def get_token(timeout = nil)
      redis do |conn|
        if timeout.nil? || timeout.positive?
          # passing timeout 0 to blpop causes it to block
          _key, current_token = conn.blpop(available_key, timeout || 0)
        else
          current_token = conn.lpop(available_key)
        end

        yield current_token, conn
      end
    end

    def unlock
      return false unless locked?
      signal(@tokens.pop)
    end

    def locked?(token = nil)
      if token
        redis { |conn| conn.hexists(grabbed_key, token) }
      else
        @tokens.each do |my_token|
          return true if locked?(my_token)
        end

        false
      end
    end

    def signal(token = nil)
      token ||= generate_unique_token

      Scripts.call(
        :signal,
        @redis_pool,
        keys: [exists_key, grabbed_key, available_key, version_key],
        argv: [token, @lock_expiration],
      )
    end

    def all_tokens
      redis do |conn|
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

    def release_stale_locks
      return unless check_staleness?

      if Gem::Version.new(SidekiqUniqueJobs.redis_version) >= Gem::Version.new('3.2')
        release_stale_locks_lua
      else
        release_stale_locks_ruby
      end
    end
    alias release release_stale_locks

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

    private

    def release_stale_locks_lua
      Scripts.call(
        :release_stale_locks,
        @redis_pool,
        keys:  [exists_key, grabbed_key, available_key, release_key],
        argv: [EXPIRES_IN, @stale_client_timeout, @lock_expiration],
      )
    end

    def release_stale_locks_ruby
      redis do |conn|
        simple_expiring_mutex(conn) do
          conn.hgetall(grabbed_key).each do |token, locked_at|
            timed_out_at = locked_at.to_f + @stale_client_timeout
            signal(token) if timed_out_at < current_time.to_f
          end
        end
      end
    end

    def simple_expiring_mutex(conn)
      cached_current_time = current_time.to_f
      my_lock_expires_at  = cached_current_time + EXPIRES_IN + 1

      return yield if conn.setnx(release_key, my_lock_expires_at)

      other_lock_expires_at = conn.get(release_key).to_f

      if other_lock_expires_at < cached_current_time
        old_expires_at = conn.getset(release_key, my_lock_expires_at).to_f
        yield if old_expires_at == other_lock_expires_at
      end
    ensure
      conn.del(release_key) if my_lock_expires_at > (current_time.to_f - 1)
    end

    def check_staleness?
      !@stale_client_timeout.nil?
    end

    def namespaced_key(variable)
      "#{@unique_digest}:#{variable}"
    end

    def current_time
      seconds, microseconds_with_frac = redis_time
      Time.at(seconds, microseconds_with_frac)
    end

    def redis_time
      redis(&:time)
    end

    def redis(&block)
      SidekiqUniqueJobs.connection(@redis_pool, &block)
    end
  end
end

require 'sidekiq_unique_jobs/lock/base_lock'
require 'sidekiq_unique_jobs/lock/until_executed'
require 'sidekiq_unique_jobs/lock/until_executing'
require 'sidekiq_unique_jobs/lock/until_timeout'
require 'sidekiq_unique_jobs/lock/while_executing'
require 'sidekiq_unique_jobs/lock/while_executing_reject'
require 'sidekiq_unique_jobs/lock/while_executing_requeue'
require 'sidekiq_unique_jobs/lock/until_and_while_executing'
