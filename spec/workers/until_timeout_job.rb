class UntilTimeoutJob
  include Sidekiq::Worker
  sidekiq_options unique: :until_timeout,
                  unique_expiration: 10 * 60
  def perform(x)
    TestClass.run(x)
  end
end
