# frozen_string_literal: true
# :nocov:

class UntilAndWhileExecutingJob
  include Sidekiq::Worker

  sidekiq_options queue: :working, unique: :until_and_while_executing, lock_timeout: 0

  def perform(one)
    [one]
  end
end
