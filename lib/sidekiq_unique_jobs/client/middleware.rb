require 'sidekiq_unique_jobs/server/middleware'

module SidekiqUniqueJobs
  module Client
    class Middleware
      SCHEDULED ||= 'scheduled'.freeze
      extend Forwardable
      def_delegators :SidekiqUniqueJobs, :connection, :config
      def_delegators :Sidekiq, :logger

      def call(worker_class, item, queue, redis_pool = nil)
        @worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)
        @item = item
        @queue = queue
        @redis_pool = redis_pool

        return yield unless unique_enabled?
        @lock = ExpiringLock.new(item)
        yield if aquire_lock
      end

      private

      attr_reader :item, :worker_class, :redis_pool, :queue, :lock

      def unique_enabled?
        worker_class.get_sidekiq_options['unique'] || item['unique']
      end

      def log_duplicate_payload?
        worker_class.get_sidekiq_options['log_duplicate_payload'] || item['log_duplicate_payload']
      end

      def aquire_lock
        return true if lock.aquire!
        warn_about_duplicate(item)
        nil
      end

      def warn_about_duplicate(item)
        logger.warn "payload is not unique #{item}" if log_duplicate_payload?
      end
    end
  end
end
