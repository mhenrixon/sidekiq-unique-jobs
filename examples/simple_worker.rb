# frozen_string_literal: true

class SimpleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default,
                  unique: :until_executed,
                  unique_args: ->(args) { [args.first] },
                  default_queue_lock_expiration: 5 * 60 * 60

  def perform(args)
    sleep 5
    [args]
  end
end
