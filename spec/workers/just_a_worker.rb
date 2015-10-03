class JustAWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, queue: 'testqueue', unique_lock: :until_executed

  def perform
  end
end
