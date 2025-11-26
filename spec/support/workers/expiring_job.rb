# frozen_string_literal: true

# :nocov:

class ExpiringJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, lock_ttl: 10 * 60

  def perform(one, two)
    [one, two]
  end
end
