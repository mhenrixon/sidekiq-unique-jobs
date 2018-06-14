# frozen_string_literal: true

class UniqueJobWithNoUniqueArgsMethod
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue,
                  retry: true,
                  backtrace: true,
                  unique: :until_executed,
                  unique_args: :filtered_args

  def perform(one, two)
    [one, two]
  end
end
