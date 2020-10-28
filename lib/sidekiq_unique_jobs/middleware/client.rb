# frozen_string_literal: true

module SidekiqUniqueJobs
  module Middleware
    # The unique sidekiq middleware for the client push
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Client
      prepend SidekiqUniqueJobs::Middleware

      # Calls this client middleware
      #   Used from Sidekiq.process_single
      #
      # @see SidekiqUniqueJobs::Middleware#call
      #
      # @see https://github.com/mperham/sidekiq/wiki/Job-Format
      # @see https://github.com/mperham/sidekiq/wiki/Middleware
      #
      # @yield when uniqueness is disable
      # @yield when the lock is successful
      def call(*, &block)
        lock(&block)
      end

      private

      def lock
        if (_token = lock_instance.lock)
          yield
        else
          warn_about_duplicate
        end
      end

      def warn_about_duplicate
        return unless log_duplicate?

        log_warn "Already locked with another job_id (#{dump_json(item)})"
      end
    end
  end
end
