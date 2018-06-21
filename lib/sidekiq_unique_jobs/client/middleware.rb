# frozen_string_literal: true

require 'sidekiq_unique_jobs/server/middleware'

module SidekiqUniqueJobs
  module Client
    class Middleware
      include SidekiqUniqueJobs::Logging
      include OptionsWithFallback

      # :reek:LongParameterList { max_params: 4 }
      def call(worker_class, item, queue, redis_pool = nil)
        @worker_class = worker_class
        @item         = item
        @queue        = queue
        @redis_pool   = redis_pool

        yield if success?
      end

      private

      attr_reader :item

      def success?
        unique_disabled? || locked?
      end

      def locked?
        locked = lock.lock
        warn_about_duplicate unless locked
        locked
      end

      def warn_about_duplicate
        return unless log_duplicate_payload?
        log_warn "payload is not unique #{item}"
      end
    end
  end
end
