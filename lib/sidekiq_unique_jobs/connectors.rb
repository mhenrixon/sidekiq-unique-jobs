module SidekiqUniqueJobs
  module Connectors
    def self.connection(redis_pool = nil, &block)
      return mock_redis if SidekiqUniqueJobs.config.mocking?
      redis_pool ? redis_pool.with(&block) : Sidekiq.redis(&block)
    end

    def self.mock_redis
      @redis_mock ||= MockRedis.new
    end
  end
end
