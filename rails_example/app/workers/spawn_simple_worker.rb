# frozen_string_literal: true

class SpawnSimpleWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(spawn_arg)
    SidekiqUniqueJobs.with_context(self.class.name) do
      logger.debug { "#{__method__}(#{spawn_arg})" }
    end
    SimpleWorker.perform_async spawn_arg
  end
end
