# frozen_string_literal: true

class SlowUntilExecutingWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executing,
                  queue: :default,
                  unique_args: (lambda do |args|
                    [args.first]
                  end)

  def perform(some_args)
    Sidekiq::Logging.with_context(self.class.name) do
      SidekiqUniqueJobs.logger.debug { "#{__method__}(#{some_args})" }
    end
    sleep 15
  end
end
