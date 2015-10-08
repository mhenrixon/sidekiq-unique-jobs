class MyUniqueJob
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue, retry: true, unique: :until_executed,
                  unique_expiration: 7_200, retry_count: 10
  def perform(_)
  end
end
