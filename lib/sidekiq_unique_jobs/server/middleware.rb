# frozen_string_literal: true

module SidekiqUniqueJobs
  module Server
    # The unique sidekiq middleware for the server processor
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Middleware
      include OptionsWithFallback

      # Runs the server middleware
      #   Used from Sidekiq::Processor#process
      # @param [Sidekiq::Worker] worker_class
      # @param [Hash] item a sidekiq job hash
      # @param [String] queue name of the queue
      # @yield when uniqueness is disabled
      # @yield when the lock class executes successfully
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
