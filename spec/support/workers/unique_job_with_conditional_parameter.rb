# frozen_string_literal: true

# :nocov:

class UniqueJobWithoutUniqueArgsParameter
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
    lock: :until_executed,
    queue: :customqueue,
    retry: true,
    lock_args_method: :unique_args

  def perform(conditional = nil)
    [conditional]
  end

  def self.unique_args; end
end
