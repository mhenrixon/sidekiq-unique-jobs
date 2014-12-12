module SidekiqUniqueJobs
  module Connectors
    class RedisPool
      def self.connection(redis_pool = nil, &block)
        return if redis_pool.nil?
        redis_pool.with(&block)
        return true
      end
    end
  end
end
