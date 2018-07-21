# frozen_string_literal: true

# :nocov:

# This class showcase a job that is considered unique disregarding any queue.
# Currently it will only be compared to other jobs that are disregarding queue.
# If one were to compare the unique keys generated against a job that doesn't have the
# queue removed it won't work.
class UniqueOnAllQueuesJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, unique_on_all_queues: true

  def perform(one, two, three = nil)
    [one, two, three]
  end
end
