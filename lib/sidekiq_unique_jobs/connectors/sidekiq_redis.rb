module SidekiqUniqueJobs
  module Connectors
    class SidekiqRedis
      def self.with_connection(_redis_pool = nil, &block)
        Sidekiq.redis(&block)
      end
    end
  end
end
