# frozen_string_literal: true

class WhileEnqueuedAndBusyJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_and_while_executing,
                  lock_timeout: 10,
                  lock_ttl: nil,
                  lock_limit: 4,
                  on_conflict: :log

  def perform
    SidekiqUniqueJobs.logger.info("jesus")
    sleep 1
    SidekiqUniqueJobs.logger.info("christ")
  end
end

# sidekiq_lock :while_enqueued, ttl: 10, wait: 5, on_conflict: :reschedule

# sidekiq_lock :until_success, ttl: 10, wait: 10, on_conflict: {
#   client: :log,
#   server: :replace
# }

# sidekiq_lock :until_success, ttl: 10, wait: 10, on_conflict: {
#   client: :raise,
#   server: :replace
# }
