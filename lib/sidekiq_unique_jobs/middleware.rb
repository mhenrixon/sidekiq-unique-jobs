# frozen_string_literal: true

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
        include SidekiqUniqueJobs::JSON
      end
    end

    def self.configure
      configure_server
      configure_client
    end

    def self.configure_server
      Sidekiq.configure_server do |config|
        config.client_middleware do |chain|
          chain.add SidekiqUniqueJobs::Middleware::Client
        end

        config.server_middleware do |chain|
          chain.add SidekiqUniqueJobs::Middleware::Server
        end
      end
    end

    def self.configure_client
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.add SidekiqUniqueJobs::Middleware::Client
        end
      end
    end
  end
end
