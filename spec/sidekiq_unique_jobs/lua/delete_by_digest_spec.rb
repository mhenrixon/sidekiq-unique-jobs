# frozen_string_literal: true

require "spec_helper"

RSpec.describe "delete_by_digest.lua", redis: :redis do
  subject(:delete_by_digest) { call_script(:delete_by_digest, [digest, SidekiqUniqueJobs::DIGESTS_ZSET]) }

  let(:job_id)      { "jobid" }
  let(:digest)      { "uniquejobs:digest" }
  let(:key)         { SidekiqUniqueJobs::Key.new(digest) }
  let(:redlock)     { SidekiqUniqueJobs::Redis::Lock.new(key) }
  let(:queued)      { redlock.queued_list }
  let(:primed)      { redlock.primed_list }
  let(:locked)      { redlock.locked_hash }
  let(:run_key)     { SidekiqUniqueJobs::Key.new("#{digest}:RUN") }
  let(:run_redlock) { SidekiqUniqueJobs::Redis::Lock.new(run_key) }
  let(:run_queued)  { redlock.queued_list }
  let(:run_primed)  { redlock.primed_list }
  let(:run_locked)  { redlock.locked_hash }
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
