# frozen_string_literal: true

module SidekiqUniqueJobs
  # Shared module for dealing with redis connections
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Connection
    def self.included(base)
      base.send(:extend, self)
    end

    # Creates a connection to redis
    # @return [Sidekiq::RedisConnection] a connection to redis
    def redis(_r_pool = nil, &block)
      Sidekiq.redis do |conn|
        conn.with(&block)
      end
    end
  end
end
