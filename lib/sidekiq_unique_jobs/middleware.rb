# frozen_string_literal: true

require "sidekiq"

module SidekiqUniqueJobs
  #
  # Provides the sidekiq middleware that makes the gem work
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  module Middleware
    def self.extended(base)
      base.class_eval do
        configure_middleware
      end
    end

    def configure_middleware
      configure_server_middleware
      configure_client_middleware
    end

    def configure_server_middleware # rubocop:disable Metrics/MethodLength
      Sidekiq.configure_server do |config|
        config.client_middleware do |chain|
          require "sidekiq_unique_jobs/client/middleware"
          if defined?(Apartment::Sidekiq::Middleware::Client)
            chain.insert_after Apartment::Sidekiq::Middleware::Client, SidekiqUniqueJobs::Client::Middleware
          else
            chain.add SidekiqUniqueJobs::Client::Middleware
          end
        end

        config.server_middleware do |chain|
          require "sidekiq_unique_jobs/server/middleware"
          if defined?(Apartment::Sidekiq::Middleware::Server)
            chain.insert_after Apartment::Sidekiq::Middleware::Server, SidekiqUniqueJobs::Server::Middleware
          else
            chain.add SidekiqUniqueJobs::Server::Middleware
          end
        end
      end
    end

    def configure_client_middleware
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          require "sidekiq_unique_jobs/client/middleware"
          if defined?(Apartment::Sidekiq::Middleware::Client)
            chain.insert_after Apartment::Sidekiq::Middleware::Client, SidekiqUniqueJobs::Client::Middleware
          else
            chain.add SidekiqUniqueJobs::Client::Middleware
          end
        end
      end
    end
  end
end
SidekiqUniqueJobs.extend SidekiqUniqueJobs::Middleware
