# frozen_string_literal: true

# :nocov:

class WhileExecutingJob
  include Sidekiq::Worker
  sidekiq_options backtrace: 10,
                  lock: :while_executing,
                  queue: :working,
                  retry: 1

  def perform(args)
    [args]
  end
end
