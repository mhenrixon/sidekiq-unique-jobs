class SpawnSimpleWorker
  include Sidekiq::Worker

  def perform(spawn_arg)
    SimpleWorker.perform_async spawn_arg
  end
end
