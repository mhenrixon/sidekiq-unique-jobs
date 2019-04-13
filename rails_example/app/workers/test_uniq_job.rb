class TestUniqJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false, unique: :until_executed

  def perform
    sleep 3.minutes
  end
end
