# frozen_string_literal: true

class NotifyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :notify_worker,
                  unique: :until_executed

  def perform(_id, _blob)
    # puts "NotifyWorker -- #{id}"
  end
end
