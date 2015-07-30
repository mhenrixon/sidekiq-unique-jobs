require 'sidekiq_unique_jobs/server/middleware'

module SidekiqUniqueJobs
  module Client
    module Strategies
      class TestingInline < Unique
        def self.elegible?
          SidekiqUniqueJobs.config.inline_testing_enabled?
        end

        def review
          _middleware.call(worker_class.new, item, queue, redis_pool) do
            super
          end
        end

        def _middleware
          SidekiqUniqueJobs::Server::Middleware.new
        end
      end
    end
  end
end
