require 'sidekiq-unique-jobs/middleware/server/unique_jobs'

module SidekiqUniqueJobs
  module Middleware
    module Client
      module Strategies
        class TestingInline < Unique
          def self.elegible?
            Config.testing_enabled? && Sidekiq::Testing.inline?
          end

          def review
            SidekiqUniqueJobs::Middleware::Server::UniqueJobs.new.call(worker_class.new, item, queue, redis_pool) do
              super
            end
          end
        end
      end
    end
  end
end
