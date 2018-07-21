# frozen_string_literal: true

# :nocov:

class InlineWorker
  include Sidekiq::Worker
  sidekiq_options lock: :while_executing, lock_timeout: 5

  def perform(one)
    TestClass.run(one)
  end
end
