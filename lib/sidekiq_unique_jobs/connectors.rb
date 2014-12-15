require 'sidekiq_unique_jobs/connectors/testing'
require 'sidekiq_unique_jobs/connectors/redis_pool'
require 'sidekiq_unique_jobs/connectors/sidekiq_redis'

module SidekiqUniqueJobs
  module Connectors
    CONNECTOR_TYPES = [Testing, RedisPool, SidekiqRedis]

    def self.connection(redis_pool = nil, &block)
      CONNECTOR_TYPES.each do |connector|
        had_connection = connector.connection(redis_pool, &block)
        return if had_connection
      end
    end
  end
end
