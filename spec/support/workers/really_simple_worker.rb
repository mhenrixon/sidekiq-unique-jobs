# frozen_string_literal: true

# :nocov:

class ReallySimpleWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  queue: :bogus

  def perform(args)
    sleep 5
    [args]
  end
end
