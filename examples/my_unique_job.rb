# frozen_string_literal: true

# :nocov:

class MyUniqueJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  lock_expiration: 7_200,
                  queue: :customqueue,
                  retry: 10

  def perform(one, two)
    [one, two]
  end
end
