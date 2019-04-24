# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "unlock.lua", redis: :redis do
  subject(:unlock) { call_script(:unlock, keys: key_args, argv: argv) }

  let(:key_args) do
    [
      key.exists,
      key.grabbed,
      key.available,
      key.version,
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
      unlock
    end

    it_behaves_like "keys are removed by unlock"
  end

  context "when a lock exists for another job_id" do
    let(:locked_jid)   { "anotherjobid" }

    before do
      call_script(:lock, keys: [key.exists, key.grabbed, key.available, key.unique_set, key.digest],
                         argv: [locked_jid, lock_ttl, lock_type])
      unlock
    end

    it { is_expected.to eq(locked_jid) }

    it_behaves_like "available key exists"
    it_behaves_like "exists key exists"
    it_behaves_like "digest exists in unique set"
  end

  context "when lock exists for the same job_id" do
    let(:locked_jid) { job_id }

    before do
      call_script(:lock, keys: key_args, argv: [job_id, lock_ttl, lock_type])
      unlock
    end

    it { is_expected.to eq(1) }
    it_behaves_like "keys are removed by unlock"
  end
end
# rubocop:enable RSpec/DescribeClass
