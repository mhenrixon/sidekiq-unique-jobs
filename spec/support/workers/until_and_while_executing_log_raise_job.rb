# frozen_string_literal: true

# :nocov:

class UntilAndWhileExecutingLogRaiseJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_and_while_executing,
                  queue: :working,
                  # lock_timeout: 0.5,
                  on_conflict: {
                    client: :log,
                    server: :raise,
                  }

  def perform(key)
    puts "I am runing now with #{key}"
  end
end
