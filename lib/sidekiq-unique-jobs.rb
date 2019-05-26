# frozen_string_literal: true

require "sidekiq_unique_jobs"

SidekiqUniqueJobs::Middleware.configure

Sidekiq.configure_server do |config|
  config.on(:startup) do
    # 1. Check for key uniquejobs:version
    # 2. Copy uniquejobs:version to uniquejobs:prev_version when key exists
    # 3. Set uniquejobs:version to the current gem version
    # 4. Register the right conversion script
  end

  # TODO: Check whether to use heartbeat or a separate threadpool
  config.on(:heartbeat) do
    # 1. Run orphan cleanup script
  end
end

Sidekiq.options[:lifecycle_events][:unique_lock]    = []
Sidekiq.options[:lifecycle_events][:unique_unlock]  = []
Sidekiq.options[:lifecycle_events][:unique_timeout] = []
