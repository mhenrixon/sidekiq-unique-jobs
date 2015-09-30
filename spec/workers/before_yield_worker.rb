class BeforeYieldWorker
  include Sidekiq::Worker

  sidekiq_options queue: :unlock_ordering
  sidekiq_options unique: true, unique_unlock_order: :before_yield

  def perform
  end
end
