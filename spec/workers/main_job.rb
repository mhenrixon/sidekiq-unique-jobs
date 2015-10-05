class MainJob
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue, unique: true, unique_lock: :until_executed
  sidekiq_options log_duplicate_payload: true

  def perform(_)
  end
end
