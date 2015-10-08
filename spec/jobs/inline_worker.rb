class InlineWorker
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(x)
    TestClass.run(x)
  end
end
