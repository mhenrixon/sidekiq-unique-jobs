# frozen_string_literal: true

module SidekiqUniqueJobs
  module Server
    class Middleware
      extend Forwardable
      def_delegators :Sidekiq, :logger
      def_instance_delegator :@worker, :class, :worker_class

      include OptionsWithFallback

      def call(worker, item, queue, redis_pool = nil)
        @worker     = worker
        @item       = item
        @queue      = queue
        @redis_pool = redis_pool
        return yield if unique_disabled?

        lock.execute(after_unlock_hook) do
          yield
        end
      end

      private

      attr_reader :redis_pool, :worker, :item

      protected

      def after_unlock_hook
        -> { worker.after_unlock if worker.respond_to?(:after_unlock) }
      end
    end
  end
end
