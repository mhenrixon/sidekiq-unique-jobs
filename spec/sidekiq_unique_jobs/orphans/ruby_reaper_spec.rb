# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Orphans::RubyReaper do
  let(:service)  { redis { |conn| described_class.new(conn) } }
  let(:digest)   { "uniquejobs:digest" }
  let(:job_id)   { "job_id" }
  let(:item)     { raw_item }
  let(:lock)     { SidekiqUniqueJobs::Lock.create(digest, job_id, lock_info) }
  let(:raw_item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "lock_digest" => digest } }
  let(:lock_info) do
    {
      "job_id" => job_id,
      "limit" => 1,
      "lock" => :while_executing,
      "time" => now_f,
      "timeout" => nil,
      "ttl" => nil,
      "lock_args" => [],
      "worker" => "MyUniqueJob",
    }
  end

  before do
    SidekiqUniqueJobs.disable!
    lock
  end

  after do
    SidekiqUniqueJobs.enable!
  end

  describe "#orphans" do
    subject(:orphans) { service.orphans }

    context "when timeout limit is hit" do
      let(:digest_one)   { "uniquejobs:digest1" }
      let(:digest_two)   { "uniquejobs:digest2" }
      let(:digest_three) { "uniquejobs:digest3" }
      let(:job_id_one)   { "jobid1" }
      let(:job_id_two)   { "jobid2" }
      let(:job_id_three) { "jobid3" }

      before do
        SidekiqUniqueJobs::Lock.create(digest_one, job_id_one)
        SidekiqUniqueJobs::Lock.create(digest_two, job_id_two)
        SidekiqUniqueJobs::Lock.create(digest_three, job_id_three)

        elapsed_ms = service.start_source + service.timeout_ms + 10

        allow(service).to receive(:elapsed_ms).and_return(elapsed_ms)
        allow(service).to receive(:belongs_to_job?).and_call_original
      end

      it "does not check for orphans" do
        expect(orphans).to be_empty
        expect(service).not_to have_received(:belongs_to_job?)
      end
    end

    context "when reaping more jobs than reaper_count" do
      let(:digest_one)   { "uniquejobs:digest1" }
      let(:digest_two)   { "uniquejobs:digest2" }
      let(:digest_three) { "uniquejobs:digest3" }
      let(:job_id_one)   { "jobid1" }
      let(:job_id_two)   { "jobid2" }
      let(:job_id_three) { "jobid3" }

      before do
        SidekiqUniqueJobs::Lock.create(digest_one, job_id_one)
        SidekiqUniqueJobs::Lock.create(digest_two, job_id_two)
        SidekiqUniqueJobs::Lock.create(digest_three, job_id_three)
      end

      it "returns the first digest" do
        SidekiqUniqueJobs.use_config(reaper_count: 1) do
          expect(orphans.size).to eq(1)
          # This is the first one to be created and should therefor be the only match
          expect(orphans).to contain_exactly(digest)
        end
      end
    end

    context "when scheduled" do
      let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

      context "without scheduled job" do
        it { is_expected.to contain_exactly(digest) }
      end

      context "with scheduled job" do
        before { push_item(item) }

        it { is_expected.to match_array([]) }
      end
    end

    context "when retried" do
      let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

      context "without job in retry" do
        it { is_expected.to contain_exactly(digest) }
      end

      context "with job in retry" do
        before { zadd("retry", Time.now.to_f.to_s, dump_json(item)) }

        it { is_expected.to match_array([]) }
      end
    end

    context "when digest exists in a queue" do
      context "without enqueued job" do
        it { is_expected.to contain_exactly(digest) }
      end

      context "with enqueued job" do
        before { push_item(item) }

        it { is_expected.to match_array([]) }
      end
    end
  end

  describe "#call" do
    context "when sidekiq queues are full" do
      before do
        stub_const("SidekiqUniqueJobs::Orphans::RubyReaper::MAX_QUEUE_LENGTH", 3)
        4.times { push_item(item) }
        allow(service).to receive(:orphans).and_call_original
      end

      it "quits early" do
        service.call

        expect(service).not_to have_received(:orphans)
      end
    end

    context "when a lock is until_expired" do
      let(:lock_info) do
        {
          "job_id" => job_id,
          "limit" => 1,
          "lock" => :until_expired,
          "time" => now_f,
          "timeout" => nil,
          "ttl" => 1,
          "lock_args" => [],
          "worker" => "MyUniqueJob",
        }
      end

      before do
        # NOTE: The below makes sure that the timing is way of in the future
        #   which allows the spec to pass and consider existing locks as `old`
        allow(service).to receive(:start_time).and_return(Time.now + 100_000)
      end

      it "clears the lock" do
        expect(zcard(SidekiqUniqueJobs::EXPIRING_DIGESTS)).to eq 1

        service.call

        expect(zcard(SidekiqUniqueJobs::EXPIRING_DIGESTS)).to eq 0
      end
    end
  end
end
