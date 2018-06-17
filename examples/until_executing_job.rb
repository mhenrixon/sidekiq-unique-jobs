# frozen_string_literal: true
# :nocov:

class UntilExecutingJob
  include Sidekiq::Worker

  sidekiq_options queue: :working, unique: :until_executing

  def perform; end
end
