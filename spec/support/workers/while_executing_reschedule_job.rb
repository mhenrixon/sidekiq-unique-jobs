# frozen_string_literal: true

# :nocov:

class WhileExecutingRescheduleJob
  include Sidekiq::Worker
  sidekiq_options backtrace: 10,
                  lock: :while_executing,
                  queue: :working,
                  on_conflict: :reschedule,
                  retry: 1

  def perform(args)
    [args]
  end
end
