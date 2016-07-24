class SlowUntilExecutingWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executing,
                  queue: :default,
                  unique_args: (lambda do |args|
                    [args.first]
                  end)

  def perform(_some_args)
    sleep 15
  end
end
