class WithoutArgumentWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  log_duplicate_payload: true

  def perform
    Sidekiq::Logging.with_context(self.class.name) do
      logger.debug { __method__.to_s }
    end
    sleep 20
  end
end
