# frozen_string_literal: true

class WithoutArgumentWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options unique: :until_executed,
                  log_duplicate_payload: true

  def perform
    SidekiqUniqueJobs.with_context(self.class.name) do
      logger.debug { __method__.to_s }
    end
    sleep 20
  end
end
