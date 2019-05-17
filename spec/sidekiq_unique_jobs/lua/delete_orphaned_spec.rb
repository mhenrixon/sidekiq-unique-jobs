# frozen_string_literal: true

require "spec_helper"

RSpec.describe "delete_orphaned.lua" do
  subject(:delete_orphaned) do
    call_script(
      :delete_orphaned,
      keys: keys,
      argv: argv
    )
  end

  let(:keys) do
    [
      SidekiqUniqueJobs::DIGESTS,
      SidekiqUniqueJobs::SCHEDULE,
      SidekiqUniqueJobs::RETRY,
    ]
  end
  let(:argv)     { [] }
  let(:digest)   { "digest" }
  let(:job_id)   { "job_id" }
  let(:digests)  { SidekiqUniqueJobs::Redis::Digests.new }
  let(:item)     { raw_item }
  let(:raw_item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "unique_digest" => digest } }

  around do |example|
    SidekiqUniqueJobs.disable!
    example.run
    SidekiqUniqueJobs.enable!
  end

  context "when digest exists in schedule set" do
    let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

    context "without enqueued job" do
      it "keeps the digest" do
        expect { delete_orphaned }.to change { digests.count }.by(-1)
      end
    end

    context "with enqueued job" do
      before { Sidekiq::Client.push(item) }

      it "keeps the digest" do
        expect { delete_orphaned }.not_to change { digests.count }.from(1)
      end
    end
  end

  context "when digest exists in retry set" do

  end

  context "when digest exists in a queue" do
    context "without enqueued job" do
      it "keeps the digest" do
        expect { delete_orphaned }.to change { digests.count }.by(-1)
      end
    end

    context "with enqueued job" do
      before { Sidekiq::Client.push(item) }

      it "keeps the digest" do
        expect { delete_orphaned }.not_to change { digests.count }.from(1)
      end
    end
  end
end
