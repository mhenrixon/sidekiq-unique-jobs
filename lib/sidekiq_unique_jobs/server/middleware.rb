require 'digest'
require 'sidekiq_unique_jobs/connectors'
require 'sidekiq_unique_jobs/server/extensions'

module SidekiqUniqueJobs
  module Server
    class Middleware
      include Extensions

      attr_reader :unlock_order, :redis_pool

      def call(worker, item, _queue, redis_pool = nil)
        operative = true
        @redis_pool = redis_pool
        decide_unlock_order(worker.class)
        lock_key = payload_hash(item)
        unlock(lock_key, item) if before_yield?
        yield
      rescue Sidekiq::Shutdown
        operative = false
        raise
      ensure
        after_yield(worker, item, lock_key) if after_yield? && operative
      end

      def decide_unlock_order(klass)
        @unlock_order = if unlock_order_configured?(klass)
                          klass.get_sidekiq_options['unique_unlock_order']
                        else
                          default_unlock_order
                        end
      end

      def unlock_order_configured?(klass)
        klass.respond_to?(:get_sidekiq_options) &&
          !klass.get_sidekiq_options['unique_unlock_order'].nil?
      end

      def default_unlock_order
        SidekiqUniqueJobs.config.default_unlock_order
      end

      def before_yield?
        unlock_order == :before_yield
      end

      def after_yield?
        unlock_order == :after_yield
      end

      protected

      def after_yield(worker, item, lock_key)
        after_unlock_hook(worker)
        unlock(lock_key, item)
      end

      def unlock(lock_key, item)
        connection do |con|
          con.eval(remove_on_match, keys: [lock_key], argv: [item['jid']])
        end
      end

      def after_unlock_hook(worker)
        worker.after_unlock if worker.respond_to?(:after_unlock)
      end

      def payload_hash(item)
        SidekiqUniqueJobs.get_payload(item['class'], item['queue'], item['args'])
      end

      def logger
        Sidekiq.logger
      end

      def connection(&block)
        SidekiqUniqueJobs::Connectors.connection(redis_pool, &block)
      end
    end
  end
end
