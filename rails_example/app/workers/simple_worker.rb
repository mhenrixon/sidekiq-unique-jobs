class SimpleWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  unique_args: -> (args) { [args.first] },
                  queue: :default,
                  default_queue_lock_expiration: 3 * 60 * 60

  def perform(_some_arg)
    sleep 60
  end
end
