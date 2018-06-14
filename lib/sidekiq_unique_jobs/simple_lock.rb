# frozen_string_literal: true

module SidekiqUniqueJobs
  class SimpleLock # rubocop:disable ClassLength
    def initialize(item, redis_pool = nil)
      @item                 = item
      @current_jid          = @item[JID_KEY]
      @unique_digest        = @item[UNIQUE_DIGEST_KEY]
      @redis_pool           = redis_pool
      @lock_expiration      = @item[SidekiqUniqueJobs::LOCK_EXPIRATION_KEY]
      @lock_timeout         = @item[SidekiqUniqueJobs::LOCK_TIMEOUT_KEY]
    end

    def exists?
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        conn.key?(exists_key)
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
      SidekiqUniqueJobs::Scripts.call(
        :acquire_lock,
        @redis_pool,
        keys: [@unique_digest],
        argv: [@current_jid],
      )
      return nil unless locked?

      if block_given?
        return_value = yield @unique_digest
      end

      return_value
    end
    alias wait lock

    def unlock
      return false unless locked?
      SidekiqUniqueJobs::Scripts.call(
        :release_lock,
        @redis_pool,
        keys: [@unique_digest],
        argv: [@current_jid, @lock_expiration],
      )

      locked?
    end

    def locked?
      SidekiqUniqueJobs.connection(@redis_pool) do |conn|
        conn.exists(@unique_digest)
      end
    end

    private

    def current_time
      if @use_local_time
        Time.now
      else
        begin
          instant = SidekiqUniqueJobs.connection(@redis_pool, &:time)
          Time.at(instant[0], instant[1])
        rescue StandardError
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
