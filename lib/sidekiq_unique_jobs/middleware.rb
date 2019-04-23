# frozen_string_literal: true

require "sidekiq"

module SidekiqUniqueJobs
  #
  # Provides the sidekiq middleware that makes the gem work
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  module Middleware
    def self.included(base)
      base.class_eval do
        include SidekiqUniqueJobs::Logging
        include SidekiqUniqueJobs::OptionsWithFallback
      end
    end

    def self.configure
      configure_server
      configure_client
    end

    def self.configure_server
      Sidekiq.configure_server do |config|
        config.client_middleware do |chain|
          require "sidekiq_unique_jobs/client_middleware"
          chain.add SidekiqUniqueJobs::ClientMiddleware
        end

        config.server_middleware do |chain|
          require "sidekiq_unique_jobs/server_middleware"
          chain.add SidekiqUniqueJobs::ServerMiddleware
        end
      end
    end

    def self.configure_client
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          require "sidekiq_unique_jobs/client_middleware"
          chain.add SidekiqUniqueJobs::ClientMiddleware
        end
      end
    end

    #
    # Wraps the middleware logic with context aware logging
    #
    #
    # @return [nil]
    #
    # @yieldreturn [void] yield to the middleware instance
    def with_logging_context
      SidekiqUniqueJobs::Job.add_uniqueness(item)
      with_configured_loggers_context do
        log_debug("started")
        yield
        log_debug("ended")
      end
      nil # Need to make sure we don't return anything here
    end

    #
    # Attempt to setup context aware logging for the given logger
    #
    #
    # @return [void] <description>
    #
    # @yield
    #
    def with_configured_loggers_context(&block)
      if logger.respond_to?(:with_context)
        logger.with_context(logging_context, &block)
      elsif defined?(Sidekiq::Logging)
        Sidekiq::Logging.with_context(logging_context, &block)
      else
        logger.warn "Don't know how to create the logging context. Please open a feature request: https://github.com/mhenrixon/sidekiq-unique-jobs/issues/new?template=feature_request.md"
      end
      nil
    end

    #
    # Setup some variables to add to each log line
    #
    #
    # @return [Hash] the context to use for each log line
    #
    def logging_context
      middleware = self.is_a?(ClientMiddleware) ? :client : :server
      digest = item["unique_digest"]

      if defined?(Sidekiq::Logging)
        "#{middleware} #{"DIG-#{digest}" if digest}"
      else
        { gem: "sidekiq-unique-jobs", middleware: middleware, digest: digest }
      end
    end
  end
end
