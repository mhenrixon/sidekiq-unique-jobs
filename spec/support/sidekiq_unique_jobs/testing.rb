# frozen_string_literal: true

module SidekiqUniqueJobs
  module Testing
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::JSON
    include SidekiqUniqueJobs::Redis
    include SidekiqUniqueJobs::Script::Caller

    module Sidekiq
      def push_item(item = {})
        ::Sidekiq::Client.push(item)
      end

      def queue_count(queue)
        redis { |conn| conn.llen("queue:#{queue}") }
      end

      def schedule_count
        zcard("schedule")
      end

      def dead_count
        zcard("dead")
      end

      def schedule_count_at(max = Time.now.to_f + 2 * 60)
        zcount("schedule", "-inf", max)
      end

      def retry_count
        zcard("retry")
      end

      def flush_redis
        redis(&:flushdb)
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end
    end

    include SidekiqUniqueJobs::Testing::Sidekiq

    def locking_jids
      queued_jids.merge(primed_jids).merge(locked_jids)
    end

    def unique_keys
      keys("uniquejobs:*")
    end

    def changelogs
      @changelogs || SidekiqUniqueJobs::Changelog.new
    end

    def digests
      @digests || SidekiqUniqueJobs::Digests.new
    end

    def queued_jids(key = nil)
      if key
        { key => lrange(key, 0, -1) }
      else
        scan_each(match: "*:QUEUED").each_with_object({}) do |redis_key, hash|
          hash[redis_key] ||= []
          hash[redis_key].concat(lrange(key, 0, -1))
        end
      end
    end

    def primed_jids(key = nil)
      if key
        { key => lrange(key, 0, -1) }
      else
        scan_each(match: "*:PRIMED").each_with_object({}) do |redis_key, hash|
          hash[redis_key] ||= []
          hash[redis_key].concat(lrange(key, 0, -1))
        end
      end
    end

    def locked_jids(key = nil)
      if key
        { key => hgetall(key).to_h }
      else
        scan_each(match: "*:LOCKED").each_with_object({}) do |redis_key, hash|
          hash[redis_key] = hgetall(redis_key).to_h
        end
      end
    end

    def now_f
      SidekiqUniqueJobs.now_f
    end
  end
end
