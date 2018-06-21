# frozen_string_literal: true

module SidekiqUniqueJobs
  module Server
    class Middleware
      include OptionsWithFallback

      def call(worker_class, item, queue)
        @worker_class = worker_class
        @item         = item
        @queue        = queue
        return yield if unique_disabled?

        lock.execute(after_unlock_hook) do
          yield
        end
      end

      protected

      attr_reader :item

      def after_unlock_hook
        -> { worker_class.after_unlock if worker_method_defined?(:after_unlock) }
      end
    end
  end
end
