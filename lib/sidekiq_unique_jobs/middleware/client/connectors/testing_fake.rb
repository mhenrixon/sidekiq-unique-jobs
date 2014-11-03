require 'sidekiq_unique_jobs/middleware/client/connectors/connector'

module SidekiqUniqueJobs
  module Middleware
    module Client
      module Connectors
        class TestingFake < Connector
          def self.eligible?(_redis_pool = nil)
            SidekiqUniqueJobs.config.testing_enabled? && Sidekiq::Testing.fake?
          end

          private

          def conn
            SidekiqUniqueJobs.redis_mock { |conn| conn }
          end
        end
      end
    end
  end
end
