class WhileEnqueuedAndBusyJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_and_while_executing,
                  lock_timeout: 10,
                  lock_ttl: nil,
                  lock_limit: 1,
                  on_conflict: :reschedule

  def perform
    SidekiqUniqueJobs.logger.info('jesus')
    sleep 1
    SidekiqUniqueJobs.logger.info('christ')
  end
end
