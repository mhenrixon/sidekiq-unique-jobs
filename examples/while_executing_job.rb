# frozen_string_literal: true

class WhileExecutingJob
  include Sidekiq::Worker
  sidekiq_options backtrace: 10,
                  queue: :working,
                  retry: 1,
                  unique: :while_executing

  def perform(args)
    [args]
  end
end
