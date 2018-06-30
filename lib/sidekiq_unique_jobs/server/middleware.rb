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

        lock.execute do
          yield
        end
      end

      protected

      attr_reader :item
    end
  end
end
