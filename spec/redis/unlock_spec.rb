# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "unlock.lua", redis: :redis do
  subject(:unlock) { call_script(:unlock, key.to_a, [job_id_one, lock_ttl, lock_type, current_time]) }

  let(:argv) do
    [
      job_id_one,
      lock_ttl,
      lock_type,
      current_time,
    ]
  end
  let(:job_id_one)   { "job_id_one" }
  let(:job_id_two)   { "job_id_two" }
  let(:lock_type)    { :until_executed }
  let(:digest)       { "uniquejobs:digest" }
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_ttl)     { nil }
  let(:locked_jid)   { job_id }
  let(:current_time) { SidekiqUniqueJobs::Timing.current_time }
  let(:concurrency)  { 1 }

  context "when unlocked" do
    it "succeedes without crashing" do
      expect { unlock }.to change { zcard(key.changelog) }.by(1)
      expect(unlock).to eq(job_id_one)
    end
  end

  context "when a lock exists for another job_id" do
    let(:locked_jid)   { "anotherjobid" }

    before do
      call_script(:queue, key.to_a, [job_id_two, lock_ttl, lock_type, current_time, concurrency])
      primed_jid = rpoplpush(key.queued, key.primed)
      call_script(:lock, key.to_a, [job_id_two, primed_jid, lock_ttl, lock_type, current_time, concurrency])
    end

    it "does not unlock" do
      expect { unlock }.to change { zcard(key.changelog) }.by(1)
    end
  end

  context "when lock exists for the same job_id" do
    let(:locked_jid) { job_id }

    before do
      call_script(:lock, keys: key.to_a, argv: argv)
      unlock
    end
  end
end
# rubocop:enable RSpec/DescribeClass
