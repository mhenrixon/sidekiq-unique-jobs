# frozen_string_literal: true

# :nocov:

class UntilExecutingJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executing, queue: :working

  def perform; end
end
