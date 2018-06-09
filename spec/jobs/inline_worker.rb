# frozen_string_literal: true

class InlineWorker
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(one)
    TestClass.run(one)
  end
end
