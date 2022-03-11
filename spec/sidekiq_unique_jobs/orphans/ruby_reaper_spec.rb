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
          expect(orphans).to match_array([digest])
        end
      end
    end

    context "when scheduled" do
      let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

      context "without scheduled job" do
        it { is_expected.to match_array([digest]) }
      end

      context "with scheduled job" do
        before { push_item(item) }

        it { is_expected.to match_array([]) }
      end
    end

    context "when retried" do
      let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

      context "without job in retry" do
        it { is_expected.to match_array([digest]) }
      end

      context "with job in retry" do
        before { zadd("retry", Time.now.to_f.to_s, dump_json(item)) }

        it { is_expected.to match_array([]) }
      end
    end

    context "when digest exists in a queue" do
      context "without enqueued job" do
        it { is_expected.to match_array([digest]) }
      end

      context "with enqueued job" do
        before { push_item(item) }

        it { is_expected.to match_array([]) }
      end
    end
  end

  describe "#call" do
    before do
      stub_const("SidekiqUniqueJobs::Orphans::RubyReaper::MAX_QUEUE_LENGTH", 3)
      4.times { push_item(item) }
    end
    it 'quits early if sidekiq queues are very full' do
      expect(service).not_to receive(:orphans)

      service.call
    end
  end
end
