# frozen_string_literal: true

# :nocov:

class WithoutArgumentJob
  include Sidekiq::Job

  sidekiq_options lock: :until_executed

  def perform
    sleep 20
  end
end
