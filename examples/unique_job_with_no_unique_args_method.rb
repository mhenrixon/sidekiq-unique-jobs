# frozen_string_literal: true

# :nocov:

class UniqueJobWithNoUniqueArgsMethod
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
                  lock: :until_executed,
                  queue: :customqueue,
                  retry: true,
                  unique_args: :filtered_args

  def perform(one, two)
    [one, two]
  end
end
