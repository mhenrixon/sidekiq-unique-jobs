# frozen_string_literal: true

# :nocov:

class UntilAndWhileExecutingJob
  include Sidekiq::Worker

  sidekiq_options queue: :working, unique: :until_and_while_executing, lock_timeout: 0, lock_expiration: nil

  def perform(sleepy_time)
    sleep(sleepy_time)
    [sleepy_time]
  end
end
