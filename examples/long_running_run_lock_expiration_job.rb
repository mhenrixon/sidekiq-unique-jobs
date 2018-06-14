# frozen_string_literal: true

class LongRunningRunLockExpirationJob
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue,
                  retry: true,
                  retry_count: 10,
                  run_lock_expiration: 3_600,
                  unique: :until_and_while_executing

  def perform(one, two)
    [one, two]
  end
end
