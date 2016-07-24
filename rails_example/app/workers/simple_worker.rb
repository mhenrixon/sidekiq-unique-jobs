class SimpleWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  queue: :default,
                  unique_args: (lambda do |args|
                    [args.first]
                  end)

  def perform(_some_args)
    sleep 1
  end
end
