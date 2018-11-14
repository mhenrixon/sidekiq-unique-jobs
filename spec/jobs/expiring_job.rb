# frozen_string_literal: true

class ExpiringJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed, unique_expiration: 10 * 60

  def perform(one, two)
    [one, two]
  end
end
