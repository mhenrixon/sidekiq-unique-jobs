# frozen_string_literal: true

class StatusJob
  include Sidekiq::Job

  sidekiq_options lock: :until_executed

  def perform(*args)
    logger.debug("This is happening: #{args}")
  end
end
