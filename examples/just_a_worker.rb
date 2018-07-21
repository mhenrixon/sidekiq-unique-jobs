# frozen_string_literal: true

# :nocov:

class JustAWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, queue: :testqueue

  def perform(options = {})
    options
  end
end
