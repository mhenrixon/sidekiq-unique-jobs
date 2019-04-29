# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "lock.lua", redis: :redis do
  subject(:lock) { call_script(:lock, keys: key.to_a, argv: argv) }

  let(:argv) do
    [
      job_id,
      lock_ttl,
      lock_type,
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
      lock
    end

    it { expect(get(digest)).to eq(job_id) }
  end

  context "when lock_type is :until_expired" do
    let(:lock_type) { :until_expired }
    let(:lock_ttl)  { 10 * 1000 }

    before { lock }

    it "creates a lock with ttl" do
      expect(lock).to eq(job_id)
      expect(ttl(digest)).to eq(lock_ttl / 1000)
      expect(pttl(digest)).to be_within(100).of(lock_ttl)
    end
  end

  context "when a lock exists" do
    before do
      set(key.digest, locked_jid)
      lock
    end

    context "when lock value is another job_id" do
      let(:locked_jid) { "bogusjobid" }

      it { is_expected.to eq(locked_jid) }
    end

    context "when lock value is same job_id" do
      let(:locked_jid) { job_id }

      it { is_expected.to eq(job_id) }
    end
  end
end
# rubocop:enable RSpec/DescribeClass
