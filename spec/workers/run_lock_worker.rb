class RunLockWorker
  include Sidekiq::Worker

  sidekiq_options unique: :while_executing, queue: :unlock_ordering
  def perform
  end
end
