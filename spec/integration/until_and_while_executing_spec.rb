# frozen_string_literal: true

RSpec.describe "SidekiqUniqueJobs::Lock::UntilAndWhileExecuting" do
  before do
    digests.delete_by_pattern("*")

    Toxiproxy.populate([
                         {
                           name: :redis,
                           listen: "localhost:21212",
                           upstream: "localhost:6379",
                         },
                       ])

    Sidekiq.configure_server do |config|
      config.redis = { port: 21_212, db: 9 }
    end

    Sidekiq.configure_client do |config|
      config.redis = { port: 21_212, db: 9 }
    end
  end

  context "when latency is high" do
    it "still locks" do
      Toxiproxy[:redis].toxic(:latency, latency: 500, jitter: 1000).apply do
        expect(UntilAndWhileExecutingLogRaiseJob.perform_async(1)).not_to be_nil
      end
    end
  end
end
