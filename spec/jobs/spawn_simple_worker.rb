class SpawnSimpleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :not_default

  def perform(arg)
    SimpleWorker.perform_async arg
  end
end
