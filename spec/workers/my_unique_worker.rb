class MyUniqueWorker
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue, retry: true, unique: true,
                  unique_expiration: 7_200, retry_count: 10,
                  unique_lock: :until_executed
  def perform(_)
  end
end
