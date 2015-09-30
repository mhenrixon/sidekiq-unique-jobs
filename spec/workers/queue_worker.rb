class QueueWorker
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue
  def perform(_)
  end
end
