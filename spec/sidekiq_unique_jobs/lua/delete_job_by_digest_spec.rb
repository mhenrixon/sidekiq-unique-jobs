# frozen_string_literal: true

RSpec.describe "delete_job_by_digest.lua" do
  subject(:delete_job_by_digest) do
    call_script(:delete_job_by_digest, options)
  end

  let(:job_id)  { "jobid" }
  let(:digest)  { digests.entries.first }
  let(:queue)   { :customqueue }
  let(:options) { { keys: keys, argv: argv } }
  let(:argv)    { [digest] }
  let(:keys) do
    [
      "#{SidekiqUniqueJobs::QUEUE}:#{queue}",
      SidekiqUniqueJobs::SCHEDULE,
      SidekiqUniqueJobs::RETRY,
    ]
  end

  context "when job doesn't exist" do
    let(:argv) { ["abcdefab"] }

    it { is_expected.to be_nil }
  end

  context "when job is retried" do
    let(:job_id) { "abcdefab" }
    let(:job)    { dump_json(item) }
    let(:item) do
      {
        "class" => "MyUniqueJob",
        "args" => [1, 2],
        "queue" => queue,
        "jid" => job_id,
        "retry_count" => 2,
        "failed_at" => Time.now.to_f,
        "lock_digest" => digest,
      }
    end

    before { zadd("retry", Time.now.to_f.to_s, job) }

    it "removes the job from the retry set" do
      expect { delete_job_by_digest }.to change { retry_count }.from(1).to(0)
    end
  end

  context "when job is scheduled" do
    before { MyUniqueJob.perform_in(2000, 1, 1) }

    it "removes the job from the scheduled set" do
      expect { delete_job_by_digest }.to change { schedule_count }.from(1).to(0)
    end
  end

  context "when job is enqueued" do
    before { MyUniqueJob.perform_async(1, 1) }

    it "removes the job from the queue" do
      expect { delete_job_by_digest }.to change { queue_count(queue) }.from(1).to(0)
    end
  end
end
