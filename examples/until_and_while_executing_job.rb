# frozen_string_literal: true

# :nocov:

class UntilAndWhileExecutingJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_and_while_executing,
                  lock_expiration: nil,
                  lock_timeout: 0,
                  queue: :working

  def perform(sleepy_time)
    sleep(sleepy_time)
    [sleepy_time]
  end
end
