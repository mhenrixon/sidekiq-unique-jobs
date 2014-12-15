require 'sidekiq_unique_jobs/connectors/testing'
require 'sidekiq_unique_jobs/connectors/redis_pool'
require 'sidekiq_unique_jobs/connectors/sidekiq_redis'

module SidekiqUniqueJobs
  module Connectors
    CONNECTOR_TYPES = [Testing, RedisPool, SidekiqRedis]

    def self.with_connection(redis_pool = nil)
      CONNECTOR_TYPES.each do |connector|
        connector.with_connection(redis_pool) do |connection|
          return yield(connection)
        end
      end
    end
  end
end
