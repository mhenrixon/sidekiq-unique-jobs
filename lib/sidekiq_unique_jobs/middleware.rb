# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Provides the sidekiq middleware that makes the gem work
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  module Middleware
    include SidekiqUniqueJobs::Logging::Middleware
    include SidekiqUniqueJobs::OptionsWithFallback
    include SidekiqUniqueJobs::JSON

    #
    # Configure both server and client
    #
    def self.configure
      configure_server
      configure_client
    end

    #
    # Configures the Sidekiq server
    #
    def self.configure_server # rubocop:disable Metrics/MethodLength
      Sidekiq.configure_server do |config|
        config.client_middleware do |chain|
          chain.add SidekiqUniqueJobs::Middleware::Client
        end

        config.server_middleware do |chain|
          chain.add SidekiqUniqueJobs::Middleware::Server
        end

        config.on(:startup) do
          SidekiqUniqueJobs::UpdateVersion.call
          SidekiqUniqueJobs::UpgradeLocks.call

          SidekiqUniqueJobs::Orphans::Manager.start
        end

        config.on(:shutdown) do
          SidekiqUniqueJobs::Orphans::Manager.stop
        end
      end
    end

    #
    # Configures the Sidekiq client
    #
    def self.configure_client
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.add SidekiqUniqueJobs::Middleware::Client
        end
      end
    end

    # The sidekiq job hash
    # @return [Hash] the Sidekiq job hash
    attr_reader :item

    #
    # This method runs before (prepended) the actual middleware implementation.
    #   This is done to reduce duplication
    #
    # @param [Sidekiq::Worker] worker_class
    # @param [Hash] item a sidekiq job hash
    # @param [String] queue name of the queue
    # @param [ConnectionPool] redis_pool only used for compatility reasons
    #
    # @return [yield<super>] <description>
    #
    # @yieldparam [<type>] if <description>
    # @yieldreturn [<type>] <describe what yield should return>
    def call(worker_class, item, queue, redis_pool = nil)
      @worker_class = worker_class
      @item         = item
      @queue        = queue
      @redis_pool   = redis_pool
      return yield if unique_disabled?

      SidekiqUniqueJobs::Job.prepare(item) unless item[LOCK_DIGEST]

      with_logging_context do
        super
      end
    end
  end
end
