# frozen_string_literal: true

class UntilExecutedWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  lock_info: true,
                  lock_timeout: 0

  def perform
    logger.info("cowboy")
    sleep(1) # hardcore processing
    logger.info("beebop")
  end
end
