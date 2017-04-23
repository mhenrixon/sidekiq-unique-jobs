# frozen_string_literal: true

# This class showcase a job that is considered unique disregarding any queue.
# Currently it will only be compared to other jobs that are disregarding queue.
# If one were to compare the unique keys generated against a job that doesn't have the
# queue removed it won't work.
class UniqueOnAllQueuesJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed, unique_on_all_queues: true

  sidekiq_retries_exhausted do |msg|
    logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end
end
