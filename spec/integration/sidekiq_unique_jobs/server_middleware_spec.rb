# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::ServerMiddleware, redis: :redis, redis_db: 9 do
  let(:middleware) { described_class.new }

  let(:queue) { "working" }

  describe "#call" do
    describe "#unlock" do
      it "does not unlock keys it does not own" do
        jid = UntilExecutedJob.perform_async
        item = Sidekiq::Queue.new(queue).find_job(jid).item

        exists_key = "uniquejobs:7f28fc7bce5b2f7ea9895080e9b2d282:EXISTS"
        expect(get(exists_key)).to eq(jid)
        set_key(exists_key, "NOT_DELETED")

        middleware.call(UntilExecutedJob.new, item, queue) do
          expect(get(exists_key)).to eq("NOT_DELETED")
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
            expect(key).to expire_in(5)
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

        unique_keys.each do |key|
          next if key.end_with?(":EXISTS")

          expect(key).to expire_in(5)
        end
      end
    end
  end
end
