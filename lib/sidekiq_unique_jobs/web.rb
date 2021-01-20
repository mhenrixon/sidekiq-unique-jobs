# frozen_string_literal: true

require_relative "web/helpers"

module SidekiqUniqueJobs
  # Utility module to help manage unique keys in redis.
  # Useful for deleting keys that for whatever reason wasn't deleted
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Web
    def self.registered(app) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      app.helpers do
        include Web::Helpers
      end

      app.get "/locks" do
        @filter         = params[:filter] || "*"
        @filter         = "*" if @filter == ""
        @count          = (params[:count] || 100).to_i
        @current_cursor = params[:cursor]
        @prev_cursor    = params[:prev_cursor]
        @pagination     = { pattern: @filter, cursor: @current_cursor, page_size: @count }
        @total_size, @next_cursor, @locks = digests.page(**@pagination)

        erb(unique_template(:locks))
      end

      app.get "/locks/delete_all" do
        digests.delete_by_pattern("*", count: digests.count)
        redirect_to :locks
      end

      app.get "/locks/:digest" do
        @digest = params[:digest]
        @lock   = SidekiqUniqueJobs::Lock.new(@digest)

        erb(unique_template(:lock))
      end

      app.get "/locks/:digest/delete" do
        digests.delete_by_digest(params[:digest])
        redirect_to :locks
      end

      app.get "/locks/:digest/jobs/:job_id/delete" do
        @digest = params[:digest]
        @lock   = SidekiqUniqueJobs::Lock.new(@digest)
        @lock.unlock(params[:job_id])

        redirect_to "locks/#{@lock.key}"
      end
    end
  end
end

begin
  require "delegate" unless defined?(DelegateClass)
  require "sidekiq/web" unless defined?(Sidekiq::Web)

  Sidekiq::Web.register(SidekiqUniqueJobs::Web)
  Sidekiq::Web.tabs["Locks"] = "locks"
  Sidekiq::Web.settings.locales << File.join(File.dirname(__FILE__), "locales")
rescue NameError, LoadError => ex
  SidekiqUniqueJobs.logger.error(ex)
end
