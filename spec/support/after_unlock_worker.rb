class AfterUnlockWorker
  include Sidekiq::Worker
  sidekiq_options queue: :working, retry: 1, backtrace: 10, unique_unlock_order: :after_yield
  sidekiq_options unique: false

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end

  def after_unlock(*)
    # NO-OP
  end
end
