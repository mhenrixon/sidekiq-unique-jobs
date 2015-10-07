class ExpiringWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed, unique_expiration: 10 * 60
end
