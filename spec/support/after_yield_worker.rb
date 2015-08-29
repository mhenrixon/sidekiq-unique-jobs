class AfterYieldWorker
  include Sidekiq::Worker
  sidekiq_options queue: :working, retry: 1, backtrace: 10, unique_unlock_order: :after_yield,
                  unique: true

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end
end
