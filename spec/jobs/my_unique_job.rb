# frozen_string_literal: true

class MyUniqueJob
  include Sidekiq::Worker

  sidekiq_options queue: :customqueue, retry: true, retry_count: 10,
                  unique: :until_executed, unique_expiration: 7_200

  def perform(one, two)
    [one, two]
  end
end
