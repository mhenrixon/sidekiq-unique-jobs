# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Orphans::Manager do
  let(:task)     { instance_spy(Concurrent::TimerTask) }
  let(:observer) { instance_spy(SidekiqUniqueJobs::Orphans::Observer) }

  describe ".start" do
    subject(:start) { described_class.start }

    before do
      allow(SidekiqUniqueJobs::Orphans::Observer).to receive(:new).and_return(observer)

      allow(described_class).to receive(:task).and_return(task)
      allow(task).to receive(:add_observer).with(observer)
      allow(task).to receive(:execute)

      allow(described_class).to receive(:log_info).and_return(nil)
    end

    context "when registered?" do
      before { redis { |conn| conn.set(SidekiqUniqueJobs::UNIQUE_REAPER, 1) } }

      it { is_expected.to eq(nil) }
    end

    context "when NOT registered?" do
      it { is_expected.to eq(task) }

      it "sets a mutex" do
        start

        expect(get(SidekiqUniqueJobs::UNIQUE_REAPER)).to eq("1")
      end

      it "logs a start message" do
        start

        expect(described_class).to have_received(:log_info).with("Starting Reaper")
      end

      it "observes the task execution" do
        start

        expect(task).to have_received(:add_observer).with(observer)
      end

      it "executes the task" do
        start

        expect(task).to have_received(:execute)
      end
    end
  end

  describe ".stop" do
    subject(:stop) { described_class.stop }

    before do
      allow(SidekiqUniqueJobs::Orphans::Observer).to receive(:new).and_return(observer)

      allow(described_class).to receive(:task).and_return(task)
      allow(task).to receive(:add_observer).with(observer)
      allow(task).to receive(:execute)

      allow(described_class).to receive(:log_info).and_return(nil)
      described_class.register_reaper_process
    end

    it { is_expected.to eq(task) }

    it "removes the mutex" do
      stop

      expect(get(SidekiqUniqueJobs::UNIQUE_REAPER)).to be_nil
    end

    it "logs a stop message" do
      stop

      expect(described_class).to have_received(:log_info).with("Stopping Reaper")
    end

    it "shuts down the task" do
      stop

      expect(task).to have_received(:shutdown)
    end
  end

  describe ".timer_task_options" do
    subject(:timer_task_options) { described_class.timer_task_options }

    let(:expected_options) do
      { run_now: true,
        execution_interval: SidekiqUniqueJobs.config.reaper_interval,
        timeout_interval: SidekiqUniqueJobs.config.reaper_timeout }
    end

    it { is_expected.to eq(expected_options) }
  end

  describe ".reaper_interval" do
    subject(:reaper_interval) { described_class.reaper_interval }

    it { is_expected.to eq(SidekiqUniqueJobs.config.reaper_interval) }
  end

  describe ".reaper_timeout" do
    subject(:reaper_timeout) { described_class.reaper_timeout }

    it { is_expected.to eq(SidekiqUniqueJobs.config.reaper_timeout) }
  end

  describe ".logging_context" do
    subject(:logging_context) { described_class.logging_context }

    before do
      allow(described_class).to receive(:logger_context_hash?).and_return(requires_hash_context)
    end

    context "when logger_context_hash?" do
      let(:requires_hash_context) { true }

      it { is_expected.to eq("uniquejobs" => "reaper") }
    end

    context "when not logger_context_hash?" do
      let(:requires_hash_context) { false }

      it { is_expected.to eq("uniquejobs=orphan-reaper") }
    end
  end
end
