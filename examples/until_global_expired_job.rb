# frozen_string_literal: true

# :nocov:

class UntilGlobalExpiredJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_expired

  def perform(arg)
    TestClass.run(arg)
  end
end
