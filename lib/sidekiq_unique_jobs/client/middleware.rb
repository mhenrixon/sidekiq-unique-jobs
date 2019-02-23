# frozen_string_literal: true

require "sidekiq_unique_jobs/server/middleware"

module SidekiqUniqueJobs
  module Client
    # The unique sidekiq middleware for the client push
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Middleware
      include SidekiqUniqueJobs::Logging
      include OptionsWithFallback

      # Calls this client middleware
      #   Used from Sidekiq.process_single
      # @param [String] worker_class name of the sidekiq worker class
      # @param [Hash] item a sidekiq job hash
      # @param [String] queue name of the queue
      # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
      # @yield when uniqueness is disable or lock successful
      def call(worker_class, item, queue, redis_pool = nil)
        @worker_class = worker_class
        @item         = item
        @queue        = queue
        @redis_pool   = redis_pool

        yield if success?
      end

      private

      # The sidekiq job hash
      # @return [Hash] the Sidekiq job hash
      attr_reader :item

      def success?
        unique_disabled? || locked?
      end

      def locked?
        SidekiqUniqueJobs::Job.add_uniqueness(item)
        SidekiqUniqueJobs.with_context(logging_context(self.class, item)) do
          locked = lock.lock
          warn_about_duplicate unless locked
          locked
        end
      end

      def warn_about_duplicate
        return unless log_duplicate_payload?

        log_warn "payload is not unique #{item}"
      end
    end
  end
end
