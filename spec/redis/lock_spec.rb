# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "lock.lua", redis: :redis do
  subject(:lock) { call_script(:lock, key.to_a, argv) }

  let(:argv) do
    [
      job_id,
      lock_ttl,
      lock_type,
      current_time,
      concurrency,
    ]
  end
  let(:job_id)       { "jobid" }
  let(:lock_type)    { :until_executed }
  let(:digest)       { "uniquejobs:digest" }
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock_ttl)     { nil }
  let(:locked_jid)   { job_id }
  let(:current_time) { SidekiqUniqueJobs::Timing.current_time }
  let(:concurrency)  { 1 }

  context "when not queued" do
    it "stores in redis" do
      expect(lock).to eq(locked_jid)

      expect(key.locked).not_to have_member(job_id)
      expect(key.queued).not_to have_member(job_id)
      expect(key.primed).not_to have_member(job_id)
    end
  end

  context "when queued" do
    let(:key_args) do
      [locked_jid, key.queued, key.primed, key.locked, key.changelog]
    end

    before do
      flush_redis
      call_script(:queue, key_args, [job_id, lock_ttl, lock_type, current_time, concurrency])
      rpoplpush(key.queued, key.primed)
    end

    context "when unlocked" do
      it "stores in redis" do
        expect(lock).to eq(locked_jid)

        expect(key.locked).to have_field(job_id).with(current_time.to_s)
        expect(key.queued).not_to have_member(job_id)
        expect(key.primed).not_to have_member(job_id)
      end
    end

    context "when locked" do
      before do
        hset(key.locked, locked_jid, current_time)
      end

      context "when lock value is another job_id" do
        let(:locked_jid) { "bogusjobid" }

        it "updates " do
          expect(lock).to eq(locked_jid)
          expect(key.locked).not_to have_member(job_id)
          expect(key.queued).not_to have_member(job_id)
        end
      end

      context "when lock value is same job_id" do
        let(:locked_jid) { job_id }

        it "updates " do
          expect(lock).to eq(locked_jid)
          expect(key.locked).to have_field(locked_jid).with(current_time.to_s)
          expect(key.queued).not_to have_member(job_id)
          expect(key.primed).to have_member(job_id)
        end
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
