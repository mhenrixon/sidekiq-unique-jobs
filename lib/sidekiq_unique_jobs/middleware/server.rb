# frozen_string_literal: true

module SidekiqUniqueJobs
  module Middleware
    # The unique sidekiq middleware for the server processor
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Server
      prepend SidekiqUniqueJobs::Middleware

      #
      # Configure the server middleware
      #
      #
      # @return [Sidekiq] the sidekiq configuration
      #
      def self.configure(config)
        config.on(:startup) do
          SidekiqUniqueJobs::UpdateVersion.call
          SidekiqUniqueJobs::UpgradeLocks.call
          SidekiqUniqueJobs::Orphans::Manager.start
        end

        config.on(:shutdown) do
          SidekiqUniqueJobs::Orphans::Manager.stop
        end

        return unless config.respond_to?(:death_handlers)

        config.death_handlers << lambda do |job, _ex|
          digest = job["lock_digest"]
          SidekiqUniqueJobs::Digests.new.delete_by_digest(digest) if digest
        end
      end

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
