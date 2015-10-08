class UntilExecutingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :working
  sidekiq_options unique: :until_executing

  def perform
  end
end
