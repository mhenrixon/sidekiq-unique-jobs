# frozen_string_literal: true

# :nocov:

class UntilExpiredJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_expired, lock_expiration: 10 * 60

  def perform(one)
    TestClass.run(one)
  end
end
