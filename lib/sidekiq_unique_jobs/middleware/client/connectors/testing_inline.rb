require 'sidekiq_unique_jobs/middleware/client/connectors/connector'
require 'sidekiq_unique_jobs/middleware/server/unique_jobs'

module SidekiqUniqueJobs
  module Middleware
    module Client
      module Connectors
        class TestingInline < Connector
          def self.eligible?(_redis_pool = nil)
            SidekiqUniqueJobs.config.testing_enabled? && Sidekiq::Testing.inline?
          end

          def review_unique
            _middleware.call(worker_class.new, item, queue, redis_pool) do
              super
            end
          end

          private

          def _middleware
            SidekiqUniqueJobs::Middleware::Server::UniqueJobs.new
          end

          def conn
            SidekiqUniqueJobs.redis_mock { |conn| conn }
          end
        end
      end
    end
  end
end
