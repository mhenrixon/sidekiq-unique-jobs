# frozen_string_literal: true

class UntilGlobalTimeoutJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_timeout

  def perform(arg)
    TestClass.run(arg)
  end
end
