class ExpiringWorker
  include Sidekiq::Worker
  sidekiq_options unique: true, unique_job_expiration: 10 * 60
end
