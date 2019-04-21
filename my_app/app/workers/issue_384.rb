class Issue384
  include Sidekiq::Worker

  sidekiq_options lock: :while_executing,
                  lock_timeout: nil,
                  on_conflict: :reschedule

  def perform
    puts 'hello'
    sleep 1
    puts 'bye'
  end
end
