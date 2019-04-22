# frozen_string_literal: true

# :nocov:

class CustomQueueJob
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue

  def perform(one, two = "two")
    [one, two]
  end
end
