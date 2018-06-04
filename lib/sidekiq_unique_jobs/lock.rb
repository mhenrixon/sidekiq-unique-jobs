# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock # rubocop:disable ClassLength
    API_VERSION = '1'
    EXPIRES_IN = 10

    # stale_client_timeout is the threshold of time before we assume
    # that something has gone terribly wrong with a client and we
    # invalidate it's lock.
    # Default is nil for which we don't check for stale clients
    # SidekiqUniqueJobs::Lock::WhileExecuting.new(item, :stale_client_timeout => 30, :redis => myRedis)
    # SidekiqUniqueJobs::Lock::WhileExecuting.new(item, :redis => myRedis)
    # SidekiqUniqueJobs::Lock::WhileExecuting.new(item, :resources => 1, :redis => myRedis)
    # SidekiqUniqueJobs::Lock::WhileExecuting.new(item, :host => "", :port => "")
    # SidekiqUniqueJobs::Lock::WhileExecuting.new(item, :path => "bla")
    def initialize(item, redis_pool = nil)
      @item                 = item
      @current_jid          = @item[JID_KEY]
      @unique_digest        = @item[UNIQUE_DIGEST_KEY]
      @redis_pool           = redis_pool
      @lock_expiration      = @item[SidekiqUniqueJobs::LOCK_EXPIRATION_KEY]
      @lock_timeout         = @item[SidekiqUniqueJobs::LOCK_TIMEOUT_KEY]
      @stale_client_timeout = @item[SidekiqUniqueJobs::STALE_CLIENT_TIMEOUT_KEY]
      @use_local_time       = @item[SidekiqUniqueJobs::USE_LOCAL_TIME_KEY]
      @reschedule           = @item[SidekiqUniqueJobs::RESCHEDULE_KEY]
      @tokens               = []
    end

    def exists_or_create!
      SidekiqUniqueJobs::Scripts.call(
        :exists_or_create,
        @redis_pool,
        keys: [exists_key, grabbed_key, available_key],
        argv: [@current_jid, @lock_expiration],
      )
    end

    def exists?
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        conn.exists(exists_key)
      end
    end

    def available_count
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        conn.llen(available_key) if conn.exists(exists_key)
      end
    end

    def delete!
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        conn.del(available_key)
        conn.del(grabbed_key)
        conn.del(exists_key)
      end
    end

    def lock(timeout = nil) # rubocop:disable MethodLength
      exists_or_create!
      release_stale_locks!

      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        if timeout.nil? || timeout.positive?
          # passing timeout 0 to blpop causes it to block
          _key, current_token = conn.blpop(available_key, timeout || 0)
        else
          current_token = conn.lpop(available_key)
        end

        return false unless current_token == @current_jid

        conn.hset(grabbed_key, current_token, current_time.to_f)
        return_value = current_token

        if block_given?
          begin
            return_value = yield current_token
          ensure
            signal(conn, current_token)
          end
        end

        return_value
      end
    end
    alias wait lock

    def unlock
      return false unless locked?
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        signal(conn)[1]
      end

      locked?
    end

    def locked?
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        conn.hexists(grabbed_key, @current_jid)
      end
    end

    def signal(conn, token = nil)
      token ||= @current_jid
      conn.multi do
        conn.hdel grabbed_key, token
        conn.lpush available_key, token

        expire_when_necessary(conn)
      end
    end

    def release_stale_locks!
      return unless check_staleness?

      if SidekiqUniqueJobs.redis_version >= '3.2'
        release_stale_locks_lua!
      else
        release_stale_locks_ruby!
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

    def release_key
      @release_key ||= namespaced_key('RELEASE')
    end

    private

    def release_stale_locks_lua!
      SidekiqUniqueJobs::Scripts.call(
        :release_stale_locks,
        @redis_pool,
        keys:  [exists_key, grabbed_key, available_key, release_key],
        argv: [EXPIRES_IN, @stale_client_timeout, @lock_expiration],
      )
    end

    def release_stale_locks_ruby!
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        simple_expiring_mutex(conn) do
          conn.hgetall(grabbed_key).each do |token, locked_at|
            timed_out_at = locked_at.to_f + @stale_client_timeout

            signal(conn, token) if timed_out_at < current_time.to_f
          end
        end
      end
    end

    def simple_expiring_mutex(conn)
      # Using the locking mechanism as described in
      # http://redis.io/commands/setnx

      cached_current_time = current_time.to_f
      my_lock_expires_at = cached_current_time + EXPIRES_IN + 1
      return false unless create_mutex(conn, my_lock_expires_at, cached_current_time)

      yield
    ensure
      # Make sure not to delete the lock in case someone else already expired
      # our lock, with one second in between to account for some lag.
      conn.del(release_key) if my_lock_expires_at > (current_time.to_f - 1)
    end

    def create_mutex(conn, my_lock_expires_at, cached_current_time)
      # return true if we got the lock
      return true if conn.setnx(release_key, my_lock_expires_at)

      # Check if expired
      other_lock_expires_at = conn.get(release_key).to_f

      return false unless other_lock_expires_at < cached_current_time

      old_expires_at = conn.getset(release_key, my_lock_expires_at).to_f
      # Check if another client started cleanup yet. If not,
      # then we now have the lock.
      old_expires_at == other_lock_expires_at
    end

    def expire_when_necessary(conn)
      return if @lock_expiration.nil?

      [available_key, exists_key].each do |key|
        conn.expire(key, @lock_expiration)
      end
    end

    def check_staleness?
      !@stale_client_timeout.nil?
    end

    def namespaced_key(variable)
      "#{@unique_digest}:#{variable}"
    end

    def current_time
      if @use_local_time
        Time.now
      else
        begin
          instant = SidekiqUniqueJobs.connection(@redis_pool, &:time)
          Time.at(instant[0], instant[1])
        rescue
          @use_local_time = true
          current_time
        end
      end
    end
  end
end

require 'sidekiq_unique_jobs/lock/prepares_items'
require 'sidekiq_unique_jobs/lock/queue_lock_base'
require 'sidekiq_unique_jobs/lock/run_lock_base'
require 'sidekiq_unique_jobs/lock/until_executed'
require 'sidekiq_unique_jobs/lock/until_executing'
require 'sidekiq_unique_jobs/lock/while_executing'
require 'sidekiq_unique_jobs/lock/until_timeout'
require 'sidekiq_unique_jobs/lock/until_and_while_executing'
