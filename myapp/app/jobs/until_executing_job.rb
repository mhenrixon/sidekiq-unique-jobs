# frozen_string_literal: true

class UntilExecutingJob
  include Sidekiq::Job

  sidekiq_options lock: :until_executing,
                  lock_timeout: 0,
                  lock_ttl: nil,
                  lock_limit: 1

  def perform
    SidekiqUniqueJobs.logger.info("hello from until_executing")
    sleep 1
    SidekiqUniqueJobs.logger.info("bye from until_executing")
  end
end
