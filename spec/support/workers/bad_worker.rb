# frozen_string_literal: true

# :nocov:

class BadWorker
  include Sidekiq::Worker

  sidekiq_options lock: :while_executing, on_conflict: :replace

  def perform(args)
    args
  end
end
