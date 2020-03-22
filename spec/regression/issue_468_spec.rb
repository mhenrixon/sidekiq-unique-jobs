RSpec.describe "Issue 468" do
  class MyWorker
    include Sidekiq::Worker
    sidekiq_options retry: 0, lock: :until_expired, lock_ttl: 5
  end

  specify do
    expect(MyWorker.perform_async).not_to eq(nil)
    expect(MyWorker.perform_async).to eq(nil)
    sleep(6)
    expect(MyWorker.perform_async).not_to eq(nil)
  end
end
