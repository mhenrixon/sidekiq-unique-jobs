module SidekiqUniqueJobs
  module Connectors
    class SidekiqRedis
      def self.conn(redis_pool = nil)
        Sidekiq.redis { |conn| conn }
      end
    end
  end
end
