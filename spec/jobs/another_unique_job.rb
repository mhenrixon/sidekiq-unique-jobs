# frozen_string_literal: true

class AnotherUniqueJob
  include Sidekiq::Worker
  sidekiq_options queue: :working2, retry: 1, backtrace: 10,
                  unique: :until_executed

  sidekiq_retries_exhausted do |msg|
    logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end
end
