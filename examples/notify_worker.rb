# frozen_string_literal: true

# :nocov:

class NotifyWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  queue: :notify_worker

  def perform(pid, blob)
    [pid, blob]
  end
end
