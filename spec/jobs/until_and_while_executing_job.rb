# frozen_string_literal: true

class UntilAndWhileExecuting
  include Sidekiq::Worker

  sidekiq_options queue: :working, unique: :until_and_while_executing

  def perform(one)
    [one]
  end
end
