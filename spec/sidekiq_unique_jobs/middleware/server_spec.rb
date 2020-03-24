# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Middleware::Server, redis_db: 9 do
  let(:middleware) { described_class.new }

  let(:queue) { "working" }

  describe "#call" do
    describe "#unlock" do
      it "does not unlock keys it does not own" do
        jid = UntilExecutedJob.perform_async
        item = Sidekiq::Queue.new(queue).find_job(jid).item

        digest = "uniquejobs:cf51f14f752c9ca8f3cfb0bbebad4abc"
        expect(get(digest)).to eq(jid)
        set(digest, "NOT_DELETED")

        middleware.call(UntilExecutedJob.new, item, queue) do
          expect(get(digest)).to eq("NOT_DELETED")
        end
      end
    end

    describe ":before_yield" do
      it "removes the lock before yielding to the worker" do
        jid = UntilExecutingJob.perform_async
        item = Sidekiq::Queue.new(queue).find_job(jid).item
        worker = UntilExecutingJob.new

        middleware.call(worker, item, queue) do
          unique_keys.all? do |key|
            expect(key).to have_ttl(5)
          end
        end
      end
    end

    describe ":after_yield" do
      it "removes the lock after yielding to the worker" do
        jid = UntilExecutedJob.perform_async
        item = Sidekiq::Queue.new(queue).find_job(jid).item

        middleware.call("UntilExecutedJob", item, queue) do
          # NO OP
        end

        unique_keys.all? do |key|
          if key.end_with?(":QUEUED")
            expect(key).to have_ttl(0).within(1)
          else
            expect(key).to have_ttl(5000)
          end
        end
      end
    end
  end
end
