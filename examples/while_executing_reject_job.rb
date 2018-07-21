# frozen_string_literal: true

# :nocov:

class WhileExecutingRejectJob
  include Sidekiq::Worker
  sidekiq_options lock: :while_executing_reject,
                  queue: :rejecting

  def perform(args)
    sleep 5
    p args
  end
end
