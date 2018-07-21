# frozen_string_literal: true

module SidekiqUniqueJobs
  # Shared module for dealing with redis connections
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Connection
    def self.included(base)
      base.send(:extend, self)
    end

    # Creates a connection to redis
    # @return [Sidekiq::RedisConnection, ConnectionPool] a connection to redis
    def redis(redis_pool = nil)
      if redis_pool
        redis_pool.with { |conn| yield conn }
      else
        Sidekiq.redis { |conn| yield conn }
      end
    end
  end
end
