# frozen_string_literal: true

# :nocov:

class WithoutArgumentJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  log_duplicate_payload: true

  def perform
    sleep 20
  end
end
