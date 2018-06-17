# frozen_string_literal: true

# :nocov:

class AnotherUniqueJob
  include Sidekiq::Worker
  sidekiq_options queue: :working2, retry: 1, backtrace: 10,
                  unique: :until_executed

  def perform(args)
    args
  end
end
