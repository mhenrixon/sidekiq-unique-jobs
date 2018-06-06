# frozen_string_literal: true

class InlineWorker
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(arg)
    TestClass.run(arg)
  end
end
