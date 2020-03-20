# frozen_string_literal: true

class WhileEnqueuedJob
  include Sidekiq::Worker

  sidekiq_options lock: :while_enqueued,
                  lock_timeout: nil,
                  lock_ttl: nil,
                  lock_limit: 1

  def perform
    SidekiqUniqueJobs.logger.info("hello")
    sleep 1
    SidekiqUniqueJobs.logger.info("bye")
  end
end
