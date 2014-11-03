require 'sidekiq_unique_jobs/middleware/server/unique_jobs'

module SidekiqUniqueJobs
  module Middleware
    module Client
      module Strategies
        class TestingInline < Unique
          def self.elegible?
            SidekiqUniqueJobs.config.testing_enabled? && Sidekiq::Testing.inline?
          end

          def review
            _middleware.call(worker_class.new, item, queue, redis_pool) do
              super
            end
          end

          def _middleware
            SidekiqUniqueJobs::Middleware::Server::UniqueJobs.new
          end
        end
      end
    end
  end
end
