# frozen_string_literal: true

class CustomQueueJob
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue
  def perform(one, two)
    [one, two]
  end
end
