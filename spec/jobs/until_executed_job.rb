# frozen_string_literal: true

# This class will lock until the job is successfully executed
#
# It will wait for 0 seconds to acquire a lock and it will expire the unique key after 2 seconds
class UntilExecutedJob
  include Sidekiq::Worker
  sidekiq_options queue: :working, retry: 1, backtrace: 10
  sidekiq_options unique: :until_executed, lock_timeout: 0, lock_expiration: nil

  sidekiq_retries_exhausted do |msg|
    logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(one, two = nil)
    # NO-OP
  end

  def after_unlock
    # NO OP
  end
end
