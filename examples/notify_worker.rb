# frozen_string_literal: true

# :nocov:

class NotifyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :notify_worker,
                  unique: :until_executed

  def perform(id, blob)
    [id, blob]
  end
end
