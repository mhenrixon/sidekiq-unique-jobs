# frozen_string_literal: true

module SidekiqUniqueJobs
  module Testing
    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Scripts::Caller

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
    end

    module Redis
      def get(key)
        redis { |conn| conn.get(key) }
      end

      def set(key, value, options = {})
        redis { |conn| conn.set(key, value, options) }
      end

      def exists?(key)
        redis { |conn| conn.exists(key) }
      end

      def hexists(hash, key)
        redis { |conn| conn.hexists(hash, key) }
      end

      def hget(key, value)
        redis { |conn| conn.hget(key, value) }
      end

      def hlen(hash, key)
        redis { |conn| conn.hlen(hash, key) }
      end

      def lrange(key, starting, ending)
        redis { |conn| conn.lrange(key, starting, ending) }
      end

      def flush_redis
        redis(&:flushdb)
      end

      def scard(queue)
        redis { |conn| conn.scard(queue) }
      end

      def smembers(key)
        redis { |conn| conn.smembers(key) }
      end

      def pttl(key)
        redis { |conn| conn.pttl(key) }
      end

      def ttl(key)
        redis { |conn| conn.ttl(key) }
      end

      def zadd(queue, timestamp, item)
        redis { |conn| conn.zadd(queue, timestamp, item) }
      end

      def zcard(queue)
        redis { |conn| conn.zcard(queue) }
      end

      def zcount(queue, min = "-inf", max = "+inf")
        redis { |conn| conn.zcount(queue, min, max) }
      end

      def zrange(key, starting = 0, ending = -1, with_scores: true)
        redis { |conn| conn.zrange(key, starting, ending, with_scores: with_scores) }
      end

      def zrem(key, value)
        redis { |conn| conn.zrem(key, value) }
      end

      def zrank(key, value)
        redis { |conn| conn.zrank(key, value) }
      end

      def zscore(key, value)
        redis { |conn| conn.zscore(key, value) }
      end
    end

    include SidekiqUniqueJobs::Testing::Redis
    include SidekiqUniqueJobs::Testing::Sidekiq

    def keys(pattern = nil)
      SidekiqUniqueJobs::Util.keys(pattern)
    end

    def unique_digests
      smembers("unique:keys")
    end

    def unique_keys
      keys("uniquejobs:*")
    end

    def free_set
      zrange("unique:free", 0, -1)
    end

    def held_set
      zrange("unique:held")
    end

    def current_time
      SidekiqUniqueJobs::Timing.current_time
    end
  end
end
