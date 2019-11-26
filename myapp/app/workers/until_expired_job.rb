class UntilExpiredJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_expired,
                  lock_timeout: 10,
                  lock_ttl: 60 * 60 * 24,
                  lock_limit: 3,
                  on_conflict: :log

  def perform
    SidekiqUniqueJobs.logger.info('hello')
    sleep 1
    SidekiqUniqueJobs.logger.info('bye')
  end
end
