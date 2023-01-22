# frozen_string_literal: true

class WhileBusyJob
  include Sidekiq::Job

  sidekiq_options lock: :while_executing,
                  lock_timeout: 10,
                  lock_ttl: nil,
                  lock_limit: 1,
                  on_conflict: :reschedule

  def perform
    logger.info("hello")
    sleep 1
    logger.info("bye")
  end
end
