# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "obtain.lua", redis: :redis do
  subject(:obtain) { call_script(:obtain, key.to_a, argv) }

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

  context "when unprepared" do
    it "stores in redis" do
      expect(obtain).to eq(locked_jid)

      expect(key.locked).not_to have_member(job_id)
      expect(key.prepared).not_to have_member(digest)
      expect(key.obtained).not_to have_member(digest)
    end
  end

  context "when prepared" do
    let(:key_args) do
      [locked_jid, key.prepared, key.obtained, key.locked, key.changelog]
    end

    before do
      flush_redis
      call_script(:prepare, key_args, argv)
      rpoplpush(key.prepared, key.obtained)
    end

    context "when no lock exists" do
      it "stores in redis" do
        expect(obtain).to eq(locked_jid)

        expect(key.locked).to have_field(job_id).with(current_time.to_s)
        expect(key.prepared).not_to have_member(job_id)
        expect(key.obtained).not_to have_member(job_id)
      end
    end

    context "when a lock exists" do
      before do
        hset(key.locked, locked_jid, current_time)
      end

      context "when lock value is another job_id" do
        let(:locked_jid) { "bogusjobid" }

        it "updates " do
          expect(obtain).to eq(locked_jid)
          expect(key.locked).not_to have_member(job_id)
          expect(key.prepared).not_to have_member(job_id)
        end
      end

      context "when lock value is same job_id" do
        let(:locked_jid) { job_id }

        it "updates " do
          expect(obtain).to eq(locked_jid)
          expect(key.locked).to have_field(locked_jid).with(current_time.to_s)
          expect(key.prepared).not_to have_member(job_id)
          expect(key.obtained).to have_member(job_id)
        end
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
