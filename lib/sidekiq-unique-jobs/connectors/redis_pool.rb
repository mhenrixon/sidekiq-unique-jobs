module SidekiqUniqueJobs
  module Connectors
    class RedisPool
      def self.conn(redis_pool = nil)
        return if redis_pool.nil?
        redis_pool.with { |conn| conn }
      end
    end
  end
end
