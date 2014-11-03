require 'sidekiq_unique_jobs/middleware/client/connectors/connector'

module SidekiqUniqueJobs
  module Middleware
    module Client
      module Connectors
        class RedisPool < Connector
          def self.eligible?(redis_pool = nil)
            !redis_pool.nil?
          end

          private

          def conn
            redis_pool.with { |conn| conn }
          end
        end
      end
    end
  end
end
