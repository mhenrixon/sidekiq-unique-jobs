# frozen_string_literal: true

class JustAWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_executed, queue: 'testqueue'

  def perform(options = {})
    options
  end
end
