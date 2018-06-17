# frozen_string_literal: true
# :nocov:

class UntilTimeoutJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_timeout, lock_expiration: 10 * 60, lock_timeout: 10

  def perform(one)
    TestClass.run(one)
  end
end
