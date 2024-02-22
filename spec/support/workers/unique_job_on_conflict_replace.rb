# frozen_string_literal: true

# :nocov:

class UniqueJobOnConflictReplace
  include Sidekiq::Worker
  sidekiq_options lock: :until_executing,
                  queue: :customqueue,
                  on_conflict: :replace

  def perform(one, two)
    [one, two]
  end
end
