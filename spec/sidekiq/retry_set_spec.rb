# frozen_string_literal: true

RSpec.describe Sidekiq::RetrySet do
  let(:locksmith)       { SidekiqUniqueJobs::Locksmith.new(item) }
  let(:args)            { [1, 2] }
  let(:worker_class)    { MyUniqueJob }
  let(:jid)             { "ajobid" }
  let(:key)             { SidekiqUniqueJobs::Key.new(unique_digest) }
  let(:lock)            { :until_executed }
  let(:lock_ttl)        { 7_200 }
  let(:queue)           { :customqueue }
  let(:retry_at)        { Time.now.to_f + 360 }
  let(:unique_digest)   { "uniquejobs:9e9b5ce5d423d3ea470977004b50ff84" }
  let(:item) do
    {
      "args" => args,
      "class" => worker_class,
      "failed_at" => Time.now.to_f,
      "jid" => jid,
      "lock" => lock,
      "lock_ttl" => lock_ttl,
      "queue" => queue,
      "retry_at" => retry_at,
      "retry_count" => 1,
      "lock_digest" => unique_digest,
    }
  end

  describe "#retry_all" do
    before do
      zadd("retry", retry_at.to_s, Sidekiq.dump_json(item))
    end

    context "when a job is locked" do
      let(:locked_jid) { locksmith.lock }

      before do
        locksmith.lock
      end

      it "can be put back on queue" do
        expect(retry_count).to eq(1)
        expect { described_class.new.retry_all }
          .to change { queue_count(queue) }
          .from(0).to(1)

        expect(retry_count).to eq(0)
      end
    end
  end
end
