class AfterUnlockWorker
  include Sidekiq::Worker
  sidekiq_options queue: :working, retry: 1, backtrace: 10
  sidekiq_options unique: true, unique_locks: [:until_executing, :while_executing, :until_executed]

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(_)
    fail 'HELL'
  end
end
