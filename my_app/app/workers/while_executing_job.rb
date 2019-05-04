class WhileExecutingJob
  include Sidekiq::Worker

  sidekiq_options lock: :while_executing,
                  lock_timeout: nil,
                  lock_expiration: nil,
                  lock_limit: 3,
                  on_conflict: :reschedule

  def perform
    SidekiqUniqueJobs.logger.info('hello')
    sleep 1
    SidekiqUniqueJobs.logger.info('bye')
  end
end
