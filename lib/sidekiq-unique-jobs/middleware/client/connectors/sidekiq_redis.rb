require 'sidekiq-unique-jobs/middleware/client/connectors/connector'

module SidekiqUniqueJobs
  module Middleware
    module Client
      module Connectors
        class SidekiqRedis < Connector
          def self.eligible?(redis_pool = nil)
            true
          end

          private

          def conn
            Sidekiq.redis { |conn| conn }
          end
        end
      end
    end
  end
end
