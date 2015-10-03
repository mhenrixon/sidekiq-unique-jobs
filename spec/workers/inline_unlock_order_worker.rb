class InlineUnlockOrderWorker
  include Sidekiq::Worker
  sidekiq_options unique: true, unique_lock: :until_timeout

  def perform(x)
    TestClass.run(x)
  end
end
