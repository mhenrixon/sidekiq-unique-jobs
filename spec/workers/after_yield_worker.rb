class AfterYieldWorker
  include Sidekiq::Worker
  sidekiq_options queue: :unlock_ordering, retry: 1, backtrace: 10
  sidekiq_options unique: true, unique_unlock_order: :after_yield

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end

  def after_unlock
    raise "HELL"
  end
end
