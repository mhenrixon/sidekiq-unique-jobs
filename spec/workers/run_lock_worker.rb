class RunLockWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, unique_locks: :while_executing, queue: :unlock_ordering
  def perform
  end
end
