# frozen_string_literal: true

class MainJob
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue, unique: :until_executed,
                  log_duplicate_payload: true

  def perform(_arg); end
end
