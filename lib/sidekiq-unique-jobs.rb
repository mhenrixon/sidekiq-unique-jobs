# frozen_string_literal: true

require "sidekiq_unique_jobs"

SidekiqUniqueJobs::Middleware.configure

Sidekiq.configure_server do |config|
  config.on(:startup) do
    SidekiqUniqueJobs::UpdateVersion.call
    # SidekiqUniqueJobs::ConvertLocks.start
  end

  # TODO: Check whether to use heartbeat or a separate threadpool
  config.on(:heartbeat) do
    # 1. Run orphan cleanup script
  end
end
