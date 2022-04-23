# frozen_string_literal: true

# :nocov:

class SimpleWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  queue: :default,
                  lock_args_method: ->(args) { [args.first] }

  def perform(args)
    sleep 5
    [args]
  end
end
