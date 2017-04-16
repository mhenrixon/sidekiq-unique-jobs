class SpawnSimpleWorker
  include Sidekiq::Worker

  def perform(spawn_arg)
    Sidekiq::Logging.with_context(self.class.name) do
      logger.debug { "#{__method__}(#{spawn_arg})" }
    end
    SimpleWorker.perform_async spawn_arg
  end
end
