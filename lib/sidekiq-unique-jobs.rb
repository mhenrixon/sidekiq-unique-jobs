# frozen_string_literal: true

require "sidekiq_unique_jobs"

SidekiqUniqueJobs::Middleware.configure

Sidekiq.configure_server do |config|
  config.on(:startup) do
  end
end

Sidekiq.options[:lifecycle_events][:unique_lock]    = []
Sidekiq.options[:lifecycle_events][:unique_unlock]  = []
Sidekiq.options[:lifecycle_events][:unique_timeout] = []
