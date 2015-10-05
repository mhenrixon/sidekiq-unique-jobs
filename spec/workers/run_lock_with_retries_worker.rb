class RunLockWithRetriesWorker
  include Sidekiq::Worker

  sidekiq_options unique: true,
                  unique_locks: :while_executing,
                  queue: :unlock_ordering,
                  run_lock_retries: 10,
                  run_lock_retry_interval: 0,
                  reschedule_on_lock_fail: true
  def perform
  end
end
