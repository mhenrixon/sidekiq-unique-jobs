require 'digest'
require 'forwardable'

module SidekiqUniqueJobs
  module Server
    class Middleware
      extend Forwardable
      def_delegators :SidekiqUniqueJobs, :connection, :payload_hash, :synchronize
      def_delegators :'SidekiqUniqueJobs.config', :default_unlock_order,
                     :default_reschedule_on_lock_fail
      def_delegators :Sidekiq, :logger

      attr_reader :redis_pool, :worker, :options, :lock

      def call(worker, item, queue, redis_pool = nil, &blk)
        @worker = worker
        @redis_pool = redis_pool
        @queue = queue
        setup_options(item, worker.class)
        @lock = ExpiringLock.new(item, redis_pool)
        send("#{unlock_order}_call", &blk)
      end

      def setup_options(_item, _klass)
        @options = {}
        options.merge!(worker.class.get_sidekiq_options) if worker_class?
      end

      def before_yield_call
        unlock
        yield
      end

      def after_yield_call(&block)
        operative = true
        after_yield_yield(&block)
      rescue Sidekiq::Shutdown
        operative = false
        raise
      ensure
        unlock if operative
      end

      def after_yield_yield
        yield
      end

      def run_lock_call
        connection(redis) do |con|
          synchronize(lock.unique_key, con, lock.item.dup.merge(options)) do
            unlock
            yield
          end
        end
      rescue SidekiqUniqueJobs::RunLockFailed
        return reschedule if reschedule_on_lock_fail
        raise
      end

      def unlock_order
        options.fetch('unique_unlock_order') { default_unlock_order }
      end

      def never_call(*)
        yield if block_given?
      end

      def reschedule_on_lock_fail
        options.fetch('reschedule_on_lock_fail') { default_reschedule_on_lock_fail }
      end

      protected

      def worker_class?
        worker.respond_to?(:get_sidekiq_options) || worker.class.respond_to?(:get_sidekiq_options)
      end

      def unlock
        after_unlock_hook if lock.release!
      end

      def after_unlock_hook
        worker.after_unlock if worker.respond_to?(:after_unlock)
      end

      def reschedule
        Sidekiq::Client.new(redis_pool).raw_push([item])
      end
    end
  end
end
