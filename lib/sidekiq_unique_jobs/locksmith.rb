# frozen_string_literal: true

module SidekiqUniqueJobs
  class Locksmith # rubocop:disable ClassLength
    API_VERSION = '1'
    EXPIRES_IN = 10

    include SidekiqUniqueJobs::Connection

    def initialize(item, redis_pool = nil)
      @concurrency          = 1
      @digest               = item[UNIQUE_DIGEST_KEY]
      @expiration           = item[LOCK_EXPIRATION_KEY]
      @jid                  = item[JID_KEY]
      @redis_pool           = redis_pool
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
        keys: [exists_key, grabbed_key, available_key, version_key],
        argv: [token, expiration],
      )
    end

    private

    attr_reader :concurrency, :digest, :expiration, :jid, :redis_pool

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
      "#{digest}:#{variable}"
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

require 'sidekiq_unique_jobs/lock/base_lock'
require 'sidekiq_unique_jobs/lock/until_executed'
require 'sidekiq_unique_jobs/lock/until_executing'
require 'sidekiq_unique_jobs/lock/until_expired'
require 'sidekiq_unique_jobs/lock/while_executing'
require 'sidekiq_unique_jobs/lock/while_executing_reject'
require 'sidekiq_unique_jobs/lock/while_executing_requeue'
require 'sidekiq_unique_jobs/lock/until_and_while_executing'
