# frozen_string_literal: true

# :nocov:

class MainJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  log_duplicate_payload: true,
                  queue: :customqueue

  def perform(arg)
    [arg]
  end
end
