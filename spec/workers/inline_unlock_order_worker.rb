class InlineUnlockOrderWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_timeout

  def perform(x)
    TestClass.run(x)
  end
end
