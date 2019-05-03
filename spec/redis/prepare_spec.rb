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

  context "without previously prepared lock" do
    its(:obtained) { is_exected.to be_in() }
    it { expect(prepare).to eq(locked_jid) }
    it { expect(get(key.digest)).to eq(job_id) }
    it { expect(pttl(key.digest)).to eq(-1) } # key exists without pttl
    it { expect(llen(key.prepared)).to eq(1) }
    it { expect(exists(key.obtained)).to eq(false) }
    it { expect(exists(key.locked)).to eq(false) }
    it { expect(zcard(key.changelog)).to eq(1) }
    it { expect { prepare }.to change { zcard(key.changelog) }.to(1)

    context "when lock_type is :until_expired" do
      let(:lock_type) { :until_expired }
      let(:lock_pttl) { 10 * 1000 }

      it { expect(prepare).to eq(locked_jid) }
      it { expect(get(key.digest)).to eq(job_id) }
      it { expect(pttl(key.digest)).to be_within(10).of(lock_pttl) }
      it { expect(llen(key.prepared)).to eq(1) }
      it { expect(exists(key.obtained)).to eq(false) }
      it { expect(exists(key.locked)).to eq(false) }
      it { expect(zcard(key.changelog)).to eq(1) }
    end
  end

  context "with existing lock_key" do
    before do
      set(key.digest, locked_jid)
      lpush(key.prepared, locked_jid)
    end

    context "with entry in locked" do
      before do
        hset(key.locked, locked_jid, current_time)
      end

      context "when within limit" do
        let(:concurrency) { 2 }

        context "when lock value is another job_id" do
          let(:locked_jid) { "bogusjobid" }

          it { expect(get(key.digest)).to eq(job_id) }
          it { expect(pttl(key.digest)).to eq(-1) } # key exists without pttl
          it { expect(llen(key.prepared)).to eq(1) }
          it { expect(rpop(key.prepared)).to eq(locked_jid) }
          it { expect(lpop(key.prepared)).to eq(job_id) }
          it { expect(exists(key.obtained)).to eq(true) }
          it { expect(hget(key.obtained, locked_jid)).to eq(current_time.to_s) }
          it { expect(exists(key.locked)).to eq(false) }
          it { expect(hget(key.locked, locked_jid)).to eq(current_time.to_s) }
          it { expect(hget(key.locked, job_id)).to eq(nil) }
          it { expect(zcard(key.changelog)).to eq(1) }
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
