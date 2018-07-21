# frozen_string_literal: true

# :nocov:

class UniqueJobOnConflictRaise
  include Sidekiq::Worker
  sidekiq_options lock: :while_executing,
                  queue: :customqueue,
                  on_conflict: :raise

  def perform(one, two)
    [one, two]
  end
end
