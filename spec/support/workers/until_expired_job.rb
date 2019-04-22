# frozen_string_literal: true

# :nocov:

class UntilExpiredJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_expired, lock_expiration: 1, lock_timeout: 0

  def perform(one)
    TestClass.run(one)
  end
end
