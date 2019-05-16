# frozen_string_literal: true

module SidekiqUniqueJobs
  module Middleware
    # The unique sidekiq middleware for the client push
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Client
      include SidekiqUniqueJobs::Middleware

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
        return yield if unique_disabled?

        with_logging_context do
          lock do
            return yield
          end
        end
      end

      private

      # The sidekiq job hash
      # @return [Hash] the Sidekiq job hash
      attr_reader :item

      def lock
        if (token = lock_instance.lock)
          yield token
        else
          warn_about_duplicate
        end
      end

      def warn_about_duplicate
        return unless log_duplicate_payload?

        log_warn "Already locked with another job_id (#{dump_json(item)})"
      end
    end
  end
end
