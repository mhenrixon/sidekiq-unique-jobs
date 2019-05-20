# frozen_string_literal: true

require "spec_helper"

RSpec.describe "delete_orphans.lua" do
  subject(:delete_orphans) do
    call_script(
      :delete_orphans,
      keys: keys,
      argv: argv,
    )
  end

  let(:keys) do
    [
      SidekiqUniqueJobs::DIGESTS,
      SidekiqUniqueJobs::SCHEDULE,
      SidekiqUniqueJobs::RETRY,
    ]
  end
  let(:argv)     { [100] }
  let(:digest)   { "digest" }
  let(:job_id)   { "job_id" }
  let(:digests)  { SidekiqUniqueJobs::Redis::Digests.new }
  let(:item)     { raw_item }
  let(:raw_item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "unique_digest" => digest } }

  before do
    SidekiqUniqueJobs.disable!
    digests.add(digest)
  end

  after do
    SidekiqUniqueJobs.enable!
  end

  context "when scheduled" do
    let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

    context "without scheduled job" do
      it "keeps the digest" do
        expect { delete_orphans }.to change { digests.count }.by(-1)
      end
    end

    context "with scheduled job" do
      before { Sidekiq::Client.push(item) }

      it "keeps the digest" do
        expect { delete_orphans }.not_to change { digests.count }.from(1)
      end
    end
  end

  context "when retried" do
    let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => current_time) }

    context "without job in retry" do
      it "keeps the digest" do
        expect { delete_orphans }.to change { digests.count }.by(-1)
      end
    end

    context "with job in retry" do
      before { Sidekiq.redis { |conn| conn.zadd("retry", Time.now.to_f.to_s, dump_json(item)) } }

      it "keeps the digest" do
        expect { delete_orphans }.not_to change { digests.count }.from(1)
      end
    end
  end

  context "when digest exists in a queue" do
    context "without enqueued job" do
      it "keeps the digest" do
        expect { delete_orphans }.to change { digests.count }.by(-1)
      end
    end

    context "with enqueued job" do
      before { Sidekiq::Client.push(item) }

      it "keeps the digest" do
        expect { delete_orphans }.not_to change { digests.count }.from(1)
      end
    end
  end
end
