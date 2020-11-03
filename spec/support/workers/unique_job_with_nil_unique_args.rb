# frozen_string_literal: true

# :nocov:

class UniqueJobWithNilUniqueArgs
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
                  lock: :until_executed,
                  queue: :customqueue,
                  retry: true,
                  lock_args_method: :unique_args

  def perform(args)
    [args]
  end

  def self.unique_args(_args)
    nil
  end
end
