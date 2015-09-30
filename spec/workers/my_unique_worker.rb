class MyUniqueWorker
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue, retry: true, unique: true,
                  unique_job_expiration: 7_200, retry_count: 10
  def perform(_)
  end
end
