# frozen_string_literal: true

# :nocov:

class LongRunningJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_and_while_executing,
                  lock_expiration: 7_200,
                  queue: :customqueue,
                  retry: 10
  def perform(one, two)
    [one, two]
  end
end
