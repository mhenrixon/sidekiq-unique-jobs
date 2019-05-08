# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "delete_by_digest.lua", redis: :redis do
  subject(:delete_by_digest) { call_script(:delete_by_digest, [digest, SidekiqUniqueJobs::DIGESTS_ZSET]) }

  let(:job_id)       { "jobid" }
  let(:digest)       { "uniquejobs:digest" }
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }
  let(:run_key)      { SidekiqUniqueJobs::Key.new("#{digest}:RUN") }
  let(:lock_ttl)     { nil }
  let(:lock_type)    { :until_executed }
  let(:limit)        { 1 }
  let(:current_time) { SidekiqUniqueJobs::Timing.current_time }

  def simulate_lock(key, job_id)
    redis do |conn|
      conn.multi do
        conn.set(key.digest, job_id)
        conn.lpush(key.queued, job_id)
        conn.lpush(key.primed, job_id)
        conn.hset(key.locked, job_id, current_time)
      end
    end
  end

  before do
    simulate_lock(key, job_id)
    simulate_lock(run_key, job_id)
  end


  it { expect(delete_by_digest).to eq(8)  }
end
# rubocop:enable RSpec/DescribeClass
