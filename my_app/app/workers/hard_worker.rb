# frozen_string_literal: true

class HardWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options lock: :until_executed,
                  queue: :default

  def perform
    SidekiqUniqueJobs.with_context(self.class.name) do
      SidekiqUniqueJobs.logger.debug { "#{__method__}" }
    end
    sleep 1
  end
end
