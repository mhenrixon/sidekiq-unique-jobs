# frozen_string_literal: true

# :nocov:

class SimpleWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  queue: :default,
                  unique_args: ->(args) { [args.first] }

  def perform(args)
    sleep 5
    [args]
  end
end
