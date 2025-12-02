# frozen_string_literal: true

# :nocov:
require "sidekiq/job"

class AnotherUniqueJobJob
  include Sidekiq::Job

  sidekiq_options backtrace: 10,
    lock: :until_executed,
    queue: :working2,
    retry: 1

  def perform(args)
    args
  end
end
