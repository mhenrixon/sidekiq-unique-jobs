# frozen_string_literal: true

module SidekiqUniqueJobs
  module Server
    # The unique sidekiq middleware for the server processor
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Middleware
      include Logging
      include OptionsWithFallback

      #
      #
      # Runs the server middleware (used from Sidekiq::Processor#process)
      #
      # @param [Sidekiq::Worker] worker_class
      # @param [Hash] item a sidekiq job hash
      # @param [String] queue name of the queue
      #
      # @see https://github.com/mperham/sidekiq/wiki/Job-Format
      # @see https://github.com/mperham/sidekiq/wiki/Middleware
      #
      # @yield when uniqueness is disabled
      # @yield when the lock is acquired
      def call(worker_class, item, queue)
        @worker_class = worker_class
        @item         = item
        @queue        = queue
        return yield if unique_disabled?

        SidekiqUniqueJobs::Job.add_uniqueness(item)
        SidekiqUniqueJobs.with_context(logging_context(self.class, item)) do
          lock.execute do
            yield
          end
        end
      end

      private

      # The sidekiq job hash
      # @return [Hash] the Sidekiq job hash
      attr_reader :item
    end
  end
end
