require 'sidekiq-unique-jobs/middleware/client/strategies/unique'
require 'sidekiq-unique-jobs/middleware/client/strategies/testing_inline'

module SidekiqUniqueJobs
  module Middleware
    module Client
      class UniqueJobs
        Strategies = [Strategies::TestingInline, Strategies::Unique]

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
          Strategies.detect { |s| s.elegible? }
        end

        # Attempt to constantize a string worker_class argument, always
        # failing back to the original argument.
        def worker_class_constantize(worker_class)
          if worker_class.is_a?(String)
            worker_class.constantize rescue worker_class
          else
            worker_class
          end
        end
      end
    end
  end
end
