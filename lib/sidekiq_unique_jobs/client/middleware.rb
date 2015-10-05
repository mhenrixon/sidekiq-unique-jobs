require 'sidekiq_unique_jobs/server/middleware'

module SidekiqUniqueJobs
  module Client
    class Middleware
      extend Forwardable
      def_delegators :SidekiqUniqueJobs, :connection, :config
      def_delegators :Sidekiq, :logger

      include OptionsWithFallback

      def call(worker_class, item, queue, redis_pool = nil)
        @worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)
        @item = item
        @queue = queue
        @redis_pool = redis_pool
        yield if ordinary_or_locked?
      end

      private

      attr_reader :item, :worker_class, :redis_pool, :queue

      def ordinary_or_locked?
        unique_disabled? || unlockable? || aquire_lock
      end

      def unlockable?
        !lockable?
      end

      def lockable?
        lock.respond_to?(:lock)
      end

      def aquire_lock
        locked = lock.lock(:client)
        warn_about_duplicate(item) unless locked
        locked
      end

      def warn_about_duplicate(item)
        logger.warn "payload is not unique #{item}" if log_duplicate_payload?
      end
    end
  end
end
