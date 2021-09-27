# frozen_string_literal: true

# :nocov:

class UntilAndWhileExecutingReplaceJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_and_while_executing,
                  queue: :working,
                  on_conflict: {
                    client: :replace,
                    server: :reschedule,
                  }

  def self.lock_args(args)
    [args[0]]
  end

  def perform(key); end
end
