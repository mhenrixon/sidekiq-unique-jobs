class RunLockWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, unique_unlock_order: :run_lock, queue: :unlock_ordering
  def perform
  end
end
