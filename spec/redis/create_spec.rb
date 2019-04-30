# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "create.lua", redis: :redis do
  include SidekiqUniqueJobs::Scripts::Caller
  subject(:create) { call_script(:create, key.to_a, argv) }

  let(:argv) do
    [
      job_id,
      lock_ttl,
      lock_type,
      SidekiqUniqueJobs::Timing.current_time,
      concurrency,
    ]
  end
  let(:job_id)      { "jobid" }
  let(:lock_type)   { :until_executed }
  let(:digest)      { "uniquejobs:digest" }
  let(:key)         { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_ttl)    { nil }
  let(:locked_jid)  { job_id }
  let(:concurrency) { 1 }

  context "without existing locks" do
    it "creates the right keys in redis" do
      expect(create).to eq(locked_jid)
      expect(unique_keys).to include(digest)
    end
  end

  context "when lock_type is :until_expired" do
    let(:lock_type) { :until_expired }
    let(:lock_ttl)  { 10 * 1000 }

    it "creates the right keys in redis" do
      expect(create).to eq(locked_jid)
      expect(unique_keys).to include(digest)
      expect(ttl(digest)).to eq(lock_ttl / 1000)
      expect(pttl(digest)).to be_within(100).of(lock_ttl)
    end

    it "creates a lock with ttl" do
      expect(create).to eq(job_id)
    end
  end

  context "when a lock exists" do
    before do
      set(key.lock_key, locked_jid)
    end

    context "when lock value is another job_id" do
      let(:locked_jid) { "bogusjobid" }

      it "returns the locked job_id" do
        expect(create).to eq(locked_jid)
      end
    end

    context "when lock value is same job_id" do
      let(:locked_jid) { job_id }

      it { expect(create).to eq(job_id) }
    end
  end
end
# rubocop:enable RSpec/DescribeClass
