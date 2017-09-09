# frozen_string_literal: true

# This class will lock until the job is successfully executed
#
# It will wait for 0 seconds to acquire a lock and it will expire the unique key after 2 seconds
class UntilExecuted2Job
  include Sidekiq::Worker
  sidekiq_options queue: :working, retry: 1, backtrace: 10
  sidekiq_options unique: :until_executed, lock_timeout: 0

  sidekiq_retries_exhausted do |msg|
    logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end

  def after_unlock
    # NO OP
  end
end
