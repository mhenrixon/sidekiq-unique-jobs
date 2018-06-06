# frozen_string_literal: true

class UntilTimeoutJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_timeout,
                  unique_expiration: 10 * 60
  def perform(arg)
    TestClass.run(arg)
  end
end
