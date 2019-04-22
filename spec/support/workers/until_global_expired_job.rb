# frozen_string_literal: true

# :nocov:

class UntilGlobalExpiredJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_expired

  def perform(arg)
    TestClass.run(arg)
  end
end
