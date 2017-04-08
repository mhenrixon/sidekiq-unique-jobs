class SimpleWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  queue: :default,
                  unique_args: (lambda do |args|
                    [args.first]
                  end)

  def perform(some_args)
    Sidekiq::Logging.with_context(self.class.name) do
      Sidekiq.logger.debug { "#{__method__}(#{some_args})" }
    end
    sleep 1
  end
end
