# frozen_string_literal: true

begin
  require 'sidekiq/web'
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # client-only usage
end

require_relative 'web/helpers'

module SidekiqUniqueJobs
  # Utility module to help manage unique keys in redis.
  # Useful for deleting keys that for whatever reason wasn't deleted
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Web
    def self.registered(app) # rubocop:disable Metrics/MethodLength
      view_path = File.join(File.expand_path(__dir__), 'views')

      app.helpers do
        include Web::Helpers
      end

      app.get '/unique_digests' do
        @total_size     = Digests.count
        @filter         = params[:filter] || '*'
        @filter         = '*' if @filter == ''
        @count          = (params[:count] || 100).to_i
        @unique_digests = Digests.all(pattern: @filter, count: @count)

        erb(unique_template(:unique_digests))
      end

      app.get '/unique_digests/:digest' do
        @digest = route_params[:digest]
        @unique_keys = Util.keys("#{@digest}*", 1000)

        erb(unique_template(:unique_digest))
      end

      app.get '/unique_digests/:digest/delete' do
        Digests.del(digest: route_params[:digest])
        redirect_to :unique_digests
      end
    end
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register SidekiqUniqueJobs::Web
  Sidekiq::Web.tabs['Unique Digests'] = 'unique_digests'
  # Sidekiq::Web.settings.locales << File.join(File.dirname(__FILE__), 'locales')
end
