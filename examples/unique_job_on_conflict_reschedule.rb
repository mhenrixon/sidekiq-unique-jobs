# frozen_string_literal: true

# :nocov:

class UniqueJobOnConflictReschedule
  include Sidekiq::Worker
  sidekiq_options lock: :while_executing,
                  queue: :customqueue,
                  on_conflict: :reschedule

  def perform(one, two)
    [one, two]
  end
end
