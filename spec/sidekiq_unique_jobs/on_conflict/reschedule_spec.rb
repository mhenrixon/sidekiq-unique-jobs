# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::OnConflict::Reschedule do
  let(:strategy)     { described_class.new(item) }
  let(:lock_digest)  { "uniquejobs:random-digest-value" }
  let(:worker_class) { "UniqueJobOnConflictReschedule" }
  let(:item) do
    { "class" => worker_class,
      "lock_digest" => lock_digest,
      "args" => [1, 2] }
  end

  describe "#call" do
    let(:call) { strategy.call }

    before do
      allow(UniqueJobOnConflictReschedule).to receive(:perform_in).and_call_original
    end

    it "schedules a job five seconds from now" do
      expect { call }.to change { schedule_count }.by(1)

      expect(UniqueJobOnConflictReschedule).to have_received(:perform_in)
        .with(5, *item["args"])
    end

    context "when not a sidekiq_worker_class?" do
      before do
        allow(strategy).to receive(:sidekiq_worker_class?).and_return(false)
        allow(strategy).to receive(:log_warn).and_call_original
      end

      it "logs a helpful warning" do
        expect { call }.not_to change { schedule_count }.from(0)

        expect(strategy).to have_received(:log_warn)
          .with("Skip rescheduling of #{lock_digest} because #{worker_class} is not a Sidekiq::Worker")
      end
    end
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to eq(false) }
  end
end
