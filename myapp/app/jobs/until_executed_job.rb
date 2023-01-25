# frozen_string_literal: true

class UntilExecutedJob
  include Sidekiq::Job

  sidekiq_options lock: :until_executed,
                  lock_info: true

  def perform
    logger.info("cowboy")
    sleep(2) # hardcore processing
    logger.info("beebop")
  end
end
