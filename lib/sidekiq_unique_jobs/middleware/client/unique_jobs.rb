require 'sidekiq_unique_jobs/middleware/client/strategies/unique'
require 'sidekiq_unique_jobs/middleware/client/strategies/testing_inline'

module SidekiqUniqueJobs
  module Middleware
    module Client
      class UniqueJobs
        STRATEGIES = [
          Strategies::TestingInline,
          Strategies::Unique
        ]

        attr_reader :item, :worker_class, :redis_pool

        def call(worker_class, item, queue, redis_pool = nil)
          @worker_class = worker_class_constantize(worker_class)
          @item = item
          @redis_pool = redis_pool

          if unique_enabled?
            strategy.review(worker_class, item, queue, redis_pool) { yield }
          else
            yield
          end
        end

        private

        def unique_enabled?
          worker_class.get_sidekiq_options['unique'] || item['unique']
        end

        def strategy
          STRATEGIES.detect(&:elegible?)
        end

        # Attempt to constantize a string worker_class argument, always
        # failing back to the original argument.
        def worker_class_constantize(worker_class)
          return worker_class unless worker_class.is_a?(String)
          worker_class.constantize
        rescue NameError
          worker_class
        end
      end
    end
  end
end
