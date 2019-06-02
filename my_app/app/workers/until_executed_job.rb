class UntilExecutedJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  lock_timeout: 10,
                  lock_ttl: 60 * 60 *24,
                  lock_limit: 5

  def perform
    logger.info('cowboy')
    sleep(1.day)
    logger.info('beebop')
  end
end
