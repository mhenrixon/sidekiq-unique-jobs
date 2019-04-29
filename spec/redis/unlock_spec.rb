# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "unlock.lua", redis: :redis do
  subject(:unlock) { call_script(:unlock, keys: key.to_a, argv: argv) }

  let(:argv) do
    [
      job_id,
      lock_ttl,
      lock_type,
      SidekiqUniqueJobs::Timing.current_time,
    ]
  end
  let(:job_id)     { "jobid" }
  let(:lock_type)  { :until_executed }
  let(:digest)     { "uniquejobs:digest" }
  let(:key)        { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_ttl)   { nil }
  let(:locked_jid) { job_id }

  context "without existing locks" do
    before do
      unlock
    end

    it { expect(get(digest)).to be_nil }
    it_behaves_like "keys are removed by unlock"
  end

  context "when a lock exists for another job_id" do
    let(:locked_jid)   { "anotherjobid" }

    before do
      call_script(:lock, keys: key.to_a, argv: [locked_jid, lock_ttl, lock_type])
      unlock
    end

    it "converts the lock and returns the other job_id" do
      expect(unlock).to eq(locked_jid)

      expect(exists?(key.digest)).to eq(true)
      expect(get(key.digest)).to eq(locked_jid)
      expect(exists?(key.exists)).to eq(false)
      expect(exists?(key.available)).to eq(false)
      expect(unique_digests).to include(digest)
      expect(exists?(key.grabbed)).to eq(false)
    end
  end

  context "when lock exists for the same job_id" do
    let(:locked_jid) { job_id }

    before do
      call_script(:lock, keys: key.to_a, argv: argv)
      unlock
    end

    it { is_expected.to eq(locked_jid) }
    it_behaves_like "keys are removed by unlock"
  end
end
# rubocop:enable RSpec/DescribeClass
