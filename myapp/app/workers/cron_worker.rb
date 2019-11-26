class CronWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  lock_timeout: 0,
                  on_conflict: :reschedule

  def perform
    puts 'hello'
    sleep 1
    puts 'bye'
  end
end
