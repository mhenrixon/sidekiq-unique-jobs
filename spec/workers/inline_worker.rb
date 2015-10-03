class InlineWorker
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(x)
    TestClass.run(x)
  end
end
