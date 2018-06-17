# frozen_string_literal: true

# :nocov:

class MyJob
  include Sidekiq::Worker
  sidekiq_options queue: :working, retry: 1, backtrace: 10

  def perform(one)
    [one]
  end
end
