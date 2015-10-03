class ExpiringWorker
  include Sidekiq::Worker
  sidekiq_options unique: true, unique_expiration: 10 * 60, unique_lock: :until_executed
end
