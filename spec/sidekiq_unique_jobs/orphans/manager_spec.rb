# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Orphans::Manager do
  let(:task)     { instance_spy(SidekiqUniqueJobs::TimerTask) }
  let(:observer) { instance_spy(SidekiqUniqueJobs::Orphans::Observer) }

  describe ".start" do
    subject(:start) { described_class.start }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }

    around do |example|
      Timecop.freeze(frozen_time, &example)
    end

    before do
      allow(SidekiqUniqueJobs::Orphans::Observer).to receive(:new).and_return(observer)

      allow(described_class).to receive_messages(task: task, log_info: nil)
      allow(task).to receive(:add_observer).with(observer)
      allow(task).to receive(:execute)
    end

    context "when registered?" do
      before { described_class.register_reaper_process }

      it { is_expected.to be_nil }
    end

    context "when disabled?" do
      before do
        allow(described_class).to receive(:disabled?).and_return(true)
      end

      it { is_expected.to be_nil }
    end

    context "when NOT registered?" do
      it { is_expected.to eq(task) }

      it "sets a mutex" do
        start

        expect(get(SidekiqUniqueJobs::UNIQUE_REAPER)).to eq(frozen_time.to_i.to_s)
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

      allow(described_class).to receive_messages(task: task, log_info: nil)
      allow(task).to receive(:add_observer).with(observer)
      allow(task).to receive(:execute)
    end

    context "when unregistered?" do
      before do
        allow(described_class).to receive(:registered?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context "when disabled?" do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context "when registered? and enabled?" do
      before do
        allow(described_class).to receive(:enabled?).and_return(true)
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
  end

  describe ".enabled?" do
    subject(:enabled) { described_class.enabled? }

    context "when SidekiqUniqueJobs.config.reaper = :lua" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :lua, &example)
      end

      it { is_expected.to be(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :ruby" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :ruby, &example)
      end

      it { is_expected.to be(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :none" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :none, &example)
      end

      it { is_expected.to be(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = nil" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: nil, &example)
      end

      it { is_expected.to be(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = false" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: false, &example)
      end

      it { is_expected.to be(false) }
    end
  end

  describe ".disabled?" do
    subject(:disabled) { described_class.disabled? }

    context "when SidekiqUniqueJobs.config.reaper = :lua" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :lua, &example)
      end

      it { is_expected.to be(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :ruby" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :ruby, &example)
      end

      it { is_expected.to be(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :none" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :none, &example)
      end

      it { is_expected.to be(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = nil" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: nil, &example)
      end

      it { is_expected.to be(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = false" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: false, &example)
      end

      it { is_expected.to be(true) }
    end
  end

  describe ".registered?" do
    subject(:registered) { described_class.registered? }

    context "when registered" do
      before { described_class.register_reaper_process }

      it { is_expected.to be(true) }
    end

    context "when unregistered" do
      it { is_expected.to be(false) }
    end
  end

  describe ".unregistered?" do
    subject(:unregistered) { described_class.unregistered? }

    context "when registered" do
      before { described_class.register_reaper_process }

      it { is_expected.to be(false) }
    end

    context "when unregistered" do
      it { is_expected.to be(true) }
    end
  end

  describe ".timer_task_options" do
    subject(:timer_task_options) { described_class.timer_task_options }

    context "when concurrent version is >= 1.1.10" do
      before do
        stub_const("Concurrent::VERSION", "1.1.10")
      end

      let(:expected_options) do
        { run_now: true, execution_interval: SidekiqUniqueJobs.config.reaper_interval }
      end

      it { is_expected.to eq(expected_options) }
    end

    context "when concurrent version is < 1.1.10" do
      before do
        stub_const("Concurrent::VERSION", "1.1.9")
      end

      let(:expected_options) do
        { run_now: true,
          execution_interval: SidekiqUniqueJobs.config.reaper_interval }
      end

      it { is_expected.to eq(expected_options) }
    end
  end

  describe ".reaper_interval" do
    subject(:reaper_interval) { described_class.reaper_interval }

    it { is_expected.to eq(SidekiqUniqueJobs.config.reaper_interval) }
  end

  describe ".register_reaper_process" do
    subject(:register_reaper_process) { described_class.register_reaper_process }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }

    around do |example|
      Timecop.freeze(frozen_time, &example)
    end

    it "writes a redis key with timestamp" do
      expect { register_reaper_process }.to change { get(SidekiqUniqueJobs::UNIQUE_REAPER) }
        .from(nil).to(frozen_time.to_i.to_s)

      expect(ttl(SidekiqUniqueJobs::UNIQUE_REAPER)).to be_within(20).of(SidekiqUniqueJobs.config.reaper_interval)
    end
  end

  describe ".refresh_reaper_mutex" do
    subject(:refresh_reaper_mutex) { described_class.refresh_reaper_mutex }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }

    around do |example|
      Timecop.freeze(frozen_time, &example)
    end

    it "updates the redis key with timestamp" do
      expect { refresh_reaper_mutex }.to change { get(SidekiqUniqueJobs::UNIQUE_REAPER) }
        .from(nil).to(frozen_time.to_i.to_s)

      expect(ttl(SidekiqUniqueJobs::UNIQUE_REAPER)).to be_within(20).of(SidekiqUniqueJobs.config.reaper_interval)
    end
  end

  describe "#default_task" do
    subject(:default_task) { described_class.default_task }

    before do
      allow(SidekiqUniqueJobs::TimerTask).to receive(:new).and_call_original
      allow(described_class).to receive(:with_logging_context).and_yield
      allow(described_class).to receive(:refresh_reaper_mutex).and_return(true)
      allow(SidekiqUniqueJobs::Orphans::Reaper).to receive(:call).and_return(true)
    end

    it "initializes a new timer task with the correct arguments" do
      expect(default_task).to be_a(SidekiqUniqueJobs::TimerTask)

      expect(SidekiqUniqueJobs::TimerTask).to have_received(:new)
        .with(described_class.timer_task_options)
    end
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
