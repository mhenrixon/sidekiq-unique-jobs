require 'forwardable'

module SidekiqUniqueJobs
  module Server
    class Middleware
      extend Forwardable
      def_delegators :Sidekiq, :logger
      def_instance_delegator :@worker, :class, :worker_class

      include OptionsWithFallback

      def call(worker, item, queue, redis_pool = nil, &blk)
        @worker = worker
        @redis_pool = redis_pool
        @queue = queue
        @item = item

        send(unique_lock, &blk)
      end

      private

      attr_reader :redis_pool, :worker, :item, :worker_class

      def until_executing
        unlock
        yield
      end

      def until_executed(&block)
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

      def while_executing
        lock.synchronize do
          yield
        end
      end

      def until_timeout
        yield if block_given?
      end

      protected

      def unlock
        after_unlock_hook if lock.unlock(:server)
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
