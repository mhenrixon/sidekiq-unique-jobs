# frozen_string_literal: true

# :nocov:

class MainJob
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  queue: :customqueue

  def perform(arg)
    [arg]
  end
end
