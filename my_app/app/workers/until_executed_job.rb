class UntilExecutedJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  lock_timeout: 0,
                  lock_expiration: nil,
                  lock_limit: 1

  def perform
    logger.info('cowboy')
    sleep 1
    logger.info('beebop')
  end
end
