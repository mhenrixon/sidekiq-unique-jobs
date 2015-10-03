class UniqueOnAllQueuesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :working, retry: 1, backtrace: 10
  sidekiq_options unique: true, unique_on_all_queues: true, unique_lock: :until_executed

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end
end
