class UntilExecutedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :unlock_ordering, retry: 1, backtrace: 10
  sidekiq_options unique: :until_executed

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end

  def after_unlock
    fail 'HELL'
  end
end
