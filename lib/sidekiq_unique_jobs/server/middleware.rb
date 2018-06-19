# frozen_string_literal: true

module SidekiqUniqueJobs
  module Server
    class Middleware
      extend Forwardable
      def_delegators :Sidekiq, :logger
      def_instance_delegator :@worker, :class, :worker_class

      include OptionsWithFallback

      def call(worker, item, queue)
        @worker     = worker
        @item       = item
        @queue      = queue
        return yield if unique_disabled?

        lock.execute(after_unlock_hook) do
          yield
        end
      end

      private

      attr_reader :worker, :item

      protected

      def after_unlock_hook
        -> { worker.after_unlock if worker.respond_to?(:after_unlock) }
      end
    end
  end
end
