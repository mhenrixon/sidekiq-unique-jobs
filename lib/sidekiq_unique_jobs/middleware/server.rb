# frozen_string_literal: true

module SidekiqUniqueJobs
  module Middleware
    # The unique sidekiq middleware for the server processor
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Server
      prepend SidekiqUniqueJobs::Middleware

      #
      #
      # Runs the server middleware (used from Sidekiq::Processor#process)
      #
      # @see SidekiqUniqueJobs::Middleware#call
      #
      # @see https://github.com/mperham/sidekiq/wiki/Job-Format
      # @see https://github.com/mperham/sidekiq/wiki/Middleware
      #
      # @yield when uniqueness is disabled
      # @yield when owning the lock
      def call(*, &block)
        lock_instance.execute(&block)
      end
    end
  end
end
