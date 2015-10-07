class UntilExecutingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :unlock_ordering
  sidekiq_options unique: :until_executing

  def perform
  end
end
