# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "delete_job_by_digest.lua", redis: :redis do
  subject(:delete_by_digest) { call_script(:delete_by_digest, keys: [SidekiqUniqueJobs::UNIQUE_SET, digest]) }

  let(:job_id)     { "jobid" }
  let(:digest)     { "uniquejobs:digest" }
  let(:key)        { SidekiqUniqueJobs::Key.new(digest) }
  let(:run_key)    { SidekiqUniqueJobs::Key.new("#{digest}:RUN") }
  let(:lock_ttl)   { nil }
  let(:locked_jid) { job_id }

  before do
    lock_jid(key, job_id)
    lock_jid(run_key, job_id)
  end

  it_behaves_like "a lock with all keys created"

  it "removes all keys for the given digest" do
    delete_by_digest
    expect(unique_keys).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
