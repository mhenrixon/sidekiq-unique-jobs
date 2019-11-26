class WhileBusyJob
  include Sidekiq::Worker

  sidekiq_options lock: :while_executing,
                  lock_timeout: 10,
                  lock_ttl: nil,
                  lock_limit: 1,
                  on_conflict: :reschedule

  def perform
    SidekiqUniqueJobs.logger.info('hello')
    sleep 1
    SidekiqUniqueJobs.logger.info('bye')
  end
end
