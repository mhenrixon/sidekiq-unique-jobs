# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  # rubocop:disable ClassLength
  class Semaphore
    EXISTS_TOKEN = "1"

    include SidekiqUniqueJobs::Connection

    attr_reader :redis_pool, :digest, :expiration, :jid, :available_key, :exists_key, :grabbed_key

    def initialize(item, redis_pool)
      @expiration           = item[LOCK_EXPIRATION_KEY]
      @digest               = item[UNIQUE_DIGEST_KEY]
      @jid                  = item[JID_KEY]
      @redis_pool           = redis_pool
      @concurrency          = 1
      @stale_client_timeout = item[:stale_client_timeout]
      @use_local_time       = item[:use_local_time]
      @available_key        = namespaced_key("AVAILABLE")
      @exists_key           = namespaced_key("EXISTS")
      @grabbed_key          = namespaced_key("GRABBED")
      @tokens               = []
    end

    def exists_or_create!
      token = redis(redis_pool) { |conn| conn.getset(exists_key, jid) }

      return true if token

      create!
    end

    def available_count
      if exists?
        redis(redis_pool) { |conn| conn.llen(available_key) }
      else
        @concurrency
      end
    end

    def delete
      return if expiration

      redis(redis_pool) do |conn|
        conn.multi do
          conn.del(available_key)
          conn.del(grabbed_key)
          conn.del(exists_key)
        end
      end
    end

    def delete!
      redis(redis_pool) do |conn|
        conn.multi do
          conn.del(available_key)
          conn.del(grabbed_key)
          conn.del(exists_key)
        end
      end
    end

    def lock(timeout = nil)
      exists_or_create!
      release_stale_locks! if check_staleness?

      return_value  = nil
      current_token = nil

      redis(redis_pool) do |conn|
        if timeout.nil? || timeout > 0
          # passing timeout 0 to blpop causes it to block
          _key, current_token = conn.blpop(available_key, timeout || 0)
        else
          current_token = conn.lpop(available_key)
        end

        return false if current_token.nil?

        @tokens.push(current_token)
        conn.hset(grabbed_key, jid, current_time.to_f)
        return_value = jid
      end

      if block_given?
        begin
          return_value = yield jid
        ensure
          unlock(current_token)
        end
      end

      return_value
    end
    alias wait lock

    def unlock
      return false unless locked?

      signal(@tokens.pop)[1]
    end

    def locked?(token = nil)
      if token
        redis(redis_pool) { |conn| conn.hexists(grabbed_key, token) }
      else
        @tokens.each do |token|
          return true if locked?(token)
        end

        false
      end
    end

    def signal(token = nil)
      token ||= jid

      redis(redis_pool) do |conn|
        conn.multi do
          conn.hdel(grabbed_key, token)
          conn.lpush(available_key, token)

          set_expiration_if_necessary(conn)
        end
      end
    end

    def exists?
      redis(redis_pool) { |conn| conn.exists(exists_key) }
    end

    def all_tokens
      redis(redis_pool) do |conn|
        conn.multi do
          conn.lrange(available_key, 0, -1)
          conn.hkeys(grabbed_key)
        end
      end.flatten
    end

    def release_stale_locks!
      simple_expiring_mutex(:release_locks, 10) do
        redis(redis_pool) do |conn|
          conn.hgetall(grabbed_key).each do |token, locked_at|
            timed_out_at = locked_at.to_f + @stale_client_timeout

            signal(token) if timed_out_at < current_time.to_f
          end
        end
      end
    end

    private

    def simple_expiring_mutex(key_name, expires_in)
      # Using the locking mechanism as described in
      # http://redis.io/commands/setnx

      key_name = namespaced_key(key_name)
      cached_current_time = current_time.to_f
      my_lock_expires_at = cached_current_time + expires_in + 1
      redis(redis_pool) do |conn|
        got_lock = conn.setnx(key_name, my_lock_expires_at)

        unless got_lock
          # Check if expired
          other_lock_expires_at = conn.get(key_name).to_f

          if other_lock_expires_at < cached_current_time
            old_expires_at = conn.getset(key_name, my_lock_expires_at).to_f

            # Check if another client started cleanup yet. If not,
            # then we now have the lock.
            got_lock = (old_expires_at == other_lock_expires_at)
          end
        end

        return false unless got_lock

        begin
          yield
        ensure
          # Make sure not to delete the lock in case someone else already expired
          # our lock, with one second in between to account for some lag.
          conn.del(key_name) if my_lock_expires_at > (current_time.to_f - 1)
        end
      end
    end

    def create!
      redis(redis_pool) do |conn|
        conn.expire(exists_key, 10)

        conn.multi do
          conn.del(grabbed_key)
          conn.del(available_key)
          @concurrency.times do |index|
            conn.rpush(available_key, index)
          end
          conn.persist(exists_key)

          set_expiration_if_necessary(conn)
        end
      end
    end

    def set_expiration_if_necessary(conn)
      return unless expiration

      [available_key, exists_key].each do |key|
        conn.expire(key, expiration)
      end
    end

    def check_staleness?
      !@stale_client_timeout.nil?
    end

    def namespaced_key(variable)
      "#{digest}:#{variable}"
    end

    def current_time
      if @use_local_time
        Time.now
      else
        begin
          instant = redis(redis_pool, &:time)
          Time.at(instant[0], instant[1])
        rescue StandardError
          @use_local_time = true
          current_time
        end
      end
    end
  end
  # rubocop:enable ClassLength
end
