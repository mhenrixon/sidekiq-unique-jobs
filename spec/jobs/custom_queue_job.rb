# frozen_string_literal: true

class CustomQueueJob
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue
  def perform(_arg); end
end
