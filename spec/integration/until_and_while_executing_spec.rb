# frozen_string_literal: true

RSpec.describe "SidekiqUniqueJobs::Lock::UntilAndWhileExecuting" do
  before do
    digests.delete_by_pattern("*")
    toxic_redis_url = ENV["CI"] ? "toxiproxy:21212" : "localhost:21212"
    redis_url       = ENV["CI"] ? ENV["REDIS_URL"] : "localhost:6379"

    Toxiproxy.host = "http://toxiproxy:8474" if ENV["CI"]
    Toxiproxy.populate([
                         {
                           name: :redis,
                           listen: toxic_redis_url,
                           upstream: redis_url,
                         },
                       ])
    Sidekiq::Testing.server_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Server
    end

    Sidekiq.configure_server do |config|
      config.redis = { port: 21_212, db: 9 }
    end

    Sidekiq.configure_client do |config|
      config.redis = { port: 21_212, db: 9 }
    end
  end

  context "when latency is high" do
    it "still locks" do
      Sidekiq::Testing.inline! do
        Toxiproxy[:redis].toxic(:latency, latency: 20).apply do
          expect(UntilAndWhileExecutingLogRaiseJob.perform_async(1)).not_to be_nil
        end
      end
    end
  end
end
