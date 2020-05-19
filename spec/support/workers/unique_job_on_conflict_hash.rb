# frozen_string_literal: true

# :nocov:

class UniqueJobOnConflictHash
  include Sidekiq::Worker

  sidekiq_options lock: :until_and_while_executing,
                  queue: :customqueue,
                  on_conflict: { client: :log, server: :reschedule }

  def perform(one, two)
    [one, two]
  end
end
