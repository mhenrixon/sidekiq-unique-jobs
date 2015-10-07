class RunLockWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, unique_lock: :while_executing, queue: :unlock_ordering
  def perform
  end
end
