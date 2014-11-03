require 'sidekiq-unique-jobs/connectors/testing'
require 'sidekiq-unique-jobs/connectors/redis_pool'
require 'sidekiq-unique-jobs/connectors/sidekiq_redis'

module SidekiqUniqueJobs
  module Connectors
    ConnectorTypes= [Testing, RedisPool, SidekiqRedis]

    def self.conn(redis_pool = nil)
      ConnectorTypes.each do |connector|
        conn = connector.conn(redis_pool)
        return conn if conn
      end
    end
  end
end
