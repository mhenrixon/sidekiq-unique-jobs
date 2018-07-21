# frozen_string_literal: true

# :nocov:

class UniqueJobOnConflictReject
  include Sidekiq::Worker
  sidekiq_options lock: :while_executing,
                  queue: :customqueue,
                  on_conflict: :reject

  def perform(one, two)
    [one, two]
  end
end
