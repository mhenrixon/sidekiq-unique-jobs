# frozen_string_literal: true

class StatusWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  def perform(*args)
    logger.debug("This is happening: #{args}")
  end
end
