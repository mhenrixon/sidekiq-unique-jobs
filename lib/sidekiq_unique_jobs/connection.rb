# frozen_string_literal: true

module SidekiqUniqueJobs
  module Connection
    def self.included(base)
      base.send(:extend, self)
    end

    def redis(redis_pool = nil)
      if redis_pool
        redis_pool.with { |conn| yield conn }
      else
        Sidekiq.redis { |conn| yield conn }
      end
    end
  end
end
