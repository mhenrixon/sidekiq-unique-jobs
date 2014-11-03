require 'sidekiq-unique-jobs/middleware/client/connectors/connector'

module SidekiqUniqueJobs
  module Middleware
    module Client
      module Connectors
        class TestingFake < Connector
          def self.eligible?(redis_pool = nil)
            Config.testing_enabled? && Sidekiq::Testing.fake?
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
