module SidekiqUniqueJobs
  module Connectors
    class RedisPool
      def self.with_connection(redis_pool = nil, &block)
        return if redis_pool.nil?
        redis_pool.with(&block)
      end
    end
  end
end
