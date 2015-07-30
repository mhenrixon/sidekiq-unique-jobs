require 'sidekiq_unique_jobs/client/strategies/unique'
require 'sidekiq_unique_jobs/client/strategies/testing_inline'

module SidekiqUniqueJobs
  module Client
    class Middleware
      STRATEGIES = [
        Strategies::TestingInline,
        Strategies::Unique
      ]

      attr_reader :item, :worker_class, :redis_pool

      def call(worker_class, item, queue, redis_pool = nil)
        @worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)
        @item = item
        @redis_pool = redis_pool

        if unique_enabled?
          strategy.review(worker_class, item, queue, redis_pool, log_duplicate_payload?) { yield }
        else
          yield
        end
      end

      private

      def unique_enabled?
        worker_class.get_sidekiq_options['unique'] || item['unique']
      end

      def log_duplicate_payload?
        worker_class.get_sidekiq_options['log_duplicate_payload'] || item['log_duplicate_payload']
      end

      def strategy
        STRATEGIES.detect(&:elegible?)
      end
    end
  end
end
