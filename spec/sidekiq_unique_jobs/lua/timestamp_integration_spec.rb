# frozen_string_literal: true

RSpec.describe "Timestamp Integration Test" do
  include SidekiqUniqueJobs::Script::Caller

  let(:digest)     { "uniquejobs:digest" }
  let(:key)        { SidekiqUniqueJobs::Key.new(digest) }
  let(:job_id)     { "job_id_one" }
  let(:lock_type)  { :until_expired }
  let(:lock_limit) { 1 }
  let(:now_f)      { SidekiqUniqueJobs.now_f }

  before do
    flush_redis
  end

  describe "timestamp calculation in expiring_digests" do
    context "when lock_ttl is 10 seconds" do
      let(:lock_ttl) { 10 }
      let(:lock_pttl) { lock_ttl * 1000 } # Convert to milliseconds
      let(:argv) { [job_id, lock_pttl, lock_type, lock_limit] }

      it "calculates expiration timestamp now + lock_ttl (in seconds) in lock.lua script" do
        # First queue the job
        call_script(:queue, key.to_a, [job_id, lock_pttl, lock_type, lock_limit])

        # Move from queued to primed
        rpoplpush(key.queued, key.primed)

        # Set info key to simulate locksmith behavior
        set(key.info, "bogus")

        # Now lock the job
        call_script(:lock, key.to_a, argv)

        # Get the score (timestamp) from expiring_digests
        score = zscore("uniquejobs:expiring_digests", digest)

        expected_timestamp = now_f + lock_ttl



        # Verify the calculation is correct
        expect(score).to be_within(1).of(expected_timestamp)
      end

      it "calculates expiration timestamp using now + lock_ttl (in seconds) in lock_until_expired.lua script" do
        # First queue the job
        call_script(:queue, key.to_a, [job_id, lock_pttl, lock_type, lock_limit])

        # Move from queued to primed
        rpoplpush(key.queued, key.primed)

        # Set info key to simulate locksmith behavior
        set(key.info, "bogus")

        # Now lock the job using the lock_until_expired script directly
        # This will call lock_until_expired.lua instead of lock.lua
        call_script(:lock_until_expired, key.to_a, argv)

        # Get the score (timestamp) from expiring_digests
        score = zscore("uniquejobs:expiring_digests", digest)

        # The expected timestamp should be: current_time + lock_ttl (in seconds)
        expected_timestamp = now_f + lock_ttl


        expect(score).to be_within(1).of(expected_timestamp)
      end
          end
    end
  end