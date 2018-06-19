# frozen_string_literal: true

# :nocov:

class WhileExecutingRejectJob
  include Sidekiq::Worker
  sidekiq_options queue: :rejecting,
                  unique: :while_executing_reject

  def perform(args)
    sleep 5
    p args
  end
end
