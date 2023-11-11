# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::OnConflict::Reschedule do
  let(:strategy)    { described_class.new(item) }
  let(:lock_digest) { "uniquejobs:random-digest-value" }
  let(:job_class)   { "UniqueJobOnConflictReschedule" }
  let(:item) do
    { "class" => job_class,
      "lock_digest" => lock_digest,
      "args" => [1, 2],
      "queue" => "default" }
  end

  describe "#call" do
    let(:call) { strategy.call }

    before do
      allow(strategy).to receive(:reflect).and_call_original
    end

    context "when pushed" do
      before do
        allow(UniqueJobOnConflictReschedule).to receive(:set)
          .with(queue: :default)
          .and_return(UniqueJobOnConflictReschedule)
        allow(UniqueJobOnConflictReschedule).to receive(:perform_in).and_call_original
      end

      context "when schedule_in is set to ten seconds" do
        around do |block|
          UniqueJobOnConflictReschedule.use_options(schedule_in: 10) do
            block.call
          end
        end

        it "schedules a job ten seconds from now" do
          expect { call }.to change { schedule_count }.by(1)

          expect(UniqueJobOnConflictReschedule).to have_received(:perform_in)
            .with(10, *item["args"])
        end
      end

      it "schedules a job five seconds from now" do
        expect { call }.to change { schedule_count }.by(1)

        expect(UniqueJobOnConflictReschedule).to have_received(:perform_in)
          .with(5, *item["args"])
      end

      it "reflects" do
        expect { call }.to change { schedule_count }.by(1)

        expect(strategy).to have_received(:reflect)
          .with(:rescheduled, item)
      end
    end

    context "when push fails" do
      before do
        allow(UniqueJobOnConflictReschedule).to receive(:set)
          .with(queue: :default)
          .and_return(UniqueJobOnConflictReschedule)
        allow(UniqueJobOnConflictReschedule).to receive(:perform_in).and_return(nil)
      end

      it "reflects" do
        expect { call }.to change { schedule_count }.by(0)

        expect(strategy).to have_received(:reflect)
          .with(:reschedule_failed, item)
      end
    end

    context "when not a sidekiq_job_class?" do
      before do
        allow(strategy).to receive(:sidekiq_job_class?).and_return(false)
        allow(strategy).to receive(:reflect).and_call_original
      end

      it "reflects" do
        expect { call }.to change { schedule_count }.by(0)

        expect(strategy).to have_received(:reflect)
          .with(:unknown_sidekiq_worker, item)
      end
    end
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to be(false) }
  end
end
