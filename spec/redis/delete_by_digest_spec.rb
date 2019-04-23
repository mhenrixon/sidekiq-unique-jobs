require "spec_helper"

RSpec.describe "delete_by_digest.lua"  do
  let(:job_id)  { "jobid" }
  let(:digest)  { "uniquejobs:digest" }
  let(:key)     { SidekiqUniqueJobs::Key.new(digest) }
  let(:run_key) { SidekiqUniqueJobs::Key.new("#{digest}:RUN") }

  before do
    lock_jid(key, job_id)
    lock_jid(run_key, job_id)
  end

  it_behaves_like "a lock with all keys created"

  subject(:delete_by_digest) { call_script(:delete_by_digest, keys: [SidekiqUniqueJobs::UNIQUE_SET, digest]) }

  it "removes all keys for the given digest" do
    delete_by_digest
    expect(unique_keys).to be_empty
  end
end
