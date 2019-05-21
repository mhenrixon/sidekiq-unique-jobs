# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::OnConflict::Replace do
  let(:strategy)      { described_class.new(item) }
  let(:unique_digest) { "uniquejobs:56c68cab5038eb57959538866377560d" }
  let(:block)         { -> { p "Hello" } }
  let(:digest)        { SidekiqUniqueJobs::Redis::Digests.new.entries.first }

  let(:item) do
    { "unique_digest" => unique_digest, "queue" => :customqueue }
  end

  describe "#call" do
    subject(:call) { strategy.call(&block) }

    before do
      jid
      digest
      allow(block).to receive(:call)
    end

    context "when job is retried" do
      let(:jid)  { "abcdefab" }
      let(:job)  { Sidekiq.dump_json(item) }
      let(:item) do
        {
          "class" => "MyUniqueJob",
          "args" => [1, 2],
          "queue" => "customqueue",
          "jid" => jid,
          "retry_count" => 2,
          "failed_at" => Time.now.to_f,
          "unique_digest" => unique_digest,
        }
      end

      before do
        Sidekiq.redis do |conn|
          conn.zadd("retry", Time.now.to_f.to_s, job)
        end
      end

      it "removes the job from the retry set" do
        expect { call }.to change { retry_count }.from(1).to(0)
        expect(block).to have_received(:call)
      end
    end

    context "when job is scheduled" do
      let(:jid) { MyUniqueJob.perform_in(2000, 1, 1) }

      it "removes the job from the scheduled set" do
        expect { call }.to change { schedule_count }.from(1).to(0)
        expect(block).to have_received(:call)
      end
    end

    context "when job is enqueued" do
      let(:jid) { MyUniqueJob.perform_async(1, 1) }

      it "removes the job from the queue" do
        expect { call }.to change { queue_count(:customqueue) }.from(1).to(0)

        expect(block).to have_received(:call)
      end
    end
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to eq(true) }
  end
end
