# frozen_string_literal: true

class InlineWorker
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing, lock_timeout: 5

  def perform(one)
    TestClass.run(one)
  end
end
