# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "prepare.lua", redis: :redis do
  include SidekiqUniqueJobs::Script::Caller
  let(:prepare) { call_script(:prepare, key.to_a, argv) }

  let(:argv) do
    [
      job_id,
      lock_pttl,
      lock_type,
      current_time,
      concurrency,
    ]
  end
  let(:job_id)       { "jobid" }
  let(:lock_type)    { :until_executed }
  let(:digest)       { "uniquejobs:digest" }
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_pttl)    { nil }
  let(:locked_jid)   { job_id }
  let(:concurrency)  { 1 }
  let(:current_time) { SidekiqUniqueJobs::Timing.current_time }

  before do
    flush_redis
  end

  shared_examples "successfully prepared" do
    it "stores the right data in redis" do
      expect(prepare).to eq(locked_jid)

      # Key for existance checks
      expect(get(key.digest)).to eq(job_id)

      if lock_pttl
        expect(pttl(key.digest)).to be_within(10).of(lock_pttl)
      else
        expect(pttl(key.digest)).to eq(-1)  # key exists without pttl
      end

      # Queue for blocking commands
      expect(llen(key.prepared)).to eq(1)

      # Obtained digests
      expect(exists(key.obtained)).to eq(false)

      # Locked job_ids
      expect(exists(key.locked)).to eq(false)
    end
  end

  context "without previously prepared lock" do
    it_behaves_like "successfully prepared"

    context "when lock_type is :until_expired" do
      let(:lock_type) { :until_expired }
      let(:lock_pttl) { 10 * 1000 }

      it_behaves_like "successfully prepared"
    end
  end

  context "with existing lock_key" do
    before do
      set(key.digest, locked_jid)
    end

    context "with entry in locked" do
      before do
        hset(key.locked, locked_jid, current_time)
      end

      context "when within limit" do
        let(:concurrency) { 2 }

        context "when lock value is another job_id" do
          let(:locked_jid) { "bogusjobid" }

          it "prepares keys in redis" do
            expect(prepare).to eq(job_id)
            expect(key.prepared).to have_member(key.digest)
          end
        end

        context "when lock value is same job_id" do
          let(:locked_jid) { job_id }

          it "prepares nothing" do
            expect(prepare).to eq(job_id)

            expect(key.prepared).not_to have_member(key.digest)
          end
        end
      end

      context "when outside limit" do
        context "when lock value is another job_id" do
          let(:locked_jid) { "bogusjobid" }

          it "prepares nothing" do
            expect(prepare).to eq(nil)

            expect(key.prepared).not_to have_member(key.digest)
          end
        end

        context "when lock value is same job_id" do
          let(:locked_jid) { job_id }

          it "prepares nothing" do
            expect(prepare).to eq(nil)

            expect(key.prepared).not_to have_member(key.digest)
          end
        end
      end
    end

    context "when lock value is another job_id" do
      let(:locked_jid) { "bogusjobid" }

      it "prepares keys in redis" do
        expect(prepare).to eq(job_id)
      end
    end

    context "when lock value is same job_id" do
      let(:locked_jid) { job_id }

      it "prepares keys in redis" do
        expect(prepare).to eq(job_id)
        expect(key.prepared).not_to have_member(key.digest)
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
