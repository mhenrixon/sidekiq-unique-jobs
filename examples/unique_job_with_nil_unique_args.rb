# frozen_string_literal: true
# :nocov:

class UniqueJobWithNilUniqueArgs
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue,
                  retry: true,
                  backtrace: true,
                  unique: :until_executed,
                  unique_args: :unique_args

  def perform(args)
    [args]
  end

  def self.unique_args(_args)
    nil
  end
end
