# frozen_string_literal: true

require "spec_helper"

RSpec.describe "delete_by_digest.lua" do
  subject(:delete_by_digest) { call_script(:delete_by_digest, [digest, SidekiqUniqueJobs::DIGESTS]) }

  let(:job_id)      { "jobid" }
  let(:digest)      { "uniquejobs:digest" }
  let(:key)         { SidekiqUniqueJobs::Key.new(digest) }
  let(:redlock)     { SidekiqUniqueJobs::Lock.new(key) }
  let(:queued)      { redlock.queued }
  let(:primed)      { redlock.primed }
  let(:locked)      { redlock.locked }
  let(:run_key)     { SidekiqUniqueJobs::Key.new("#{digest}:RUN") }
  let(:run_redlock) { SidekiqUniqueJobs::Lock.new(run_key) }
  let(:run_queued)  { redlock.queued }
  let(:run_primed)  { redlock.primed }
  let(:run_locked)  { redlock.locked }
  let(:lock_ttl)    { nil }
  let(:lock_type)   { :until_executed }
  let(:lock_limit)  { 1 }

  before do
    simulate_lock(key, job_id)
    simulate_lock(run_key, job_id)
  end

  it "deletes the expected keys from redis" do
    expect(delete_by_digest).to eq(8)

    expect(queued.count).to be == 0
    expect(primed.count).to be == 0
    expect(locked.count).to be == 0

    expect(run_queued.count).to be == 0
    expect(run_primed.count).to be == 0
    expect(run_locked.count).to be == 0
  end
end
