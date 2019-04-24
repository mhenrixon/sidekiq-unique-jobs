# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "lock.lua", redis: :redis do
  subject(:lock) { call_script(:lock, keys: key_args, argv: argv) }

  let(:key_args) do
    [
      key.exists,
      key.grabbed,
      key.available,
      key.unique_set,
      key.digest,
    ]
  end
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

    it_behaves_like "keys created by other locks than until_expired"
  end

  context "when lock_type is :until_expired" do
    let(:lock_type) { :until_expired }
    let(:lock_ttl)  { 10 }

    before { lock }

    it_behaves_like "keys created by until_expired"
  end

  context "when a lock exists" do
    before do
      set(key.exists, locked_jid)
      lock
    end

    context "when lock value is another job_id" do
      let(:locked_jid) { "anotherjobid" }

      it { is_expected.to eq(locked_jid) }
    end

    context "when lock value is same job_id" do
      let(:locked_jid) { job_id }

      it_behaves_like "keys created by other locks than until_expired"

      it { is_expected.to eq(job_id) }
    end
  end

  context "when a deprecated lock exists" do
    before do
      set(key.digest, locked_jid)
      lock
    end

    context "when lock value is another job_id" do
      let(:locked_jid) { "anotherjobid" }

      it { is_expected.to eq(locked_jid) }
    end

    context "when lock value is same job_id" do
      it_behaves_like "keys created by other locks than until_expired"
      it { is_expected.to eq(job_id) }
    end

    context "when lock value is '2'" do
      let(:locked_jid) { "2" }

      it_behaves_like "keys created by other locks than until_expired"
      it { is_expected.to eq(job_id) }
    end
  end
end
# rubocop:enable RSpec/DescribeClass
