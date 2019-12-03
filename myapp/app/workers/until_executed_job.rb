class UntilExecutedJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  lock_timeout: 0,
                  lock_ttl: 0,
                  lock_limit: 5

  def perform
    logger.info('cowboy')
    sleep(1)
    logger.info('beebop')
  end
end
