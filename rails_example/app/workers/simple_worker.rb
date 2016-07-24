class SimpleWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  queue: :default,
                  unique_args: (lambda do |args|
                    [args.first]
                  end)

  def perform(some_args)
    sleep 5
  end
end
