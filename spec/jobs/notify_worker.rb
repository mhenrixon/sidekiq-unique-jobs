class NotifyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :notify_worker,
                  unique: :until_executed

  def perform(id, _blob)
    # puts "NotifyWorker -- #{id}"
  end
end
