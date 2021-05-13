# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Orphans::ReaperRessurector do
  let(:manager) { SidekiqUniqueJobs::Orphans::Manager }
  let(:task)    { instance_spy(SidekiqUniqueJobs::TimerTask) }

  describe "#start" do
    subject(:start) { described_class.start }

    let(:frozen_time) { Time.new(1982, 6, 8, 14, 15, 34) }

    around do |example|
      Timecop.freeze(frozen_time, &example)
    end

    before do
      allow(described_class).to receive(:task).and_return(task)
      allow(task).to receive(:execute)

      allow(described_class).to receive(:log_info).and_return(nil)
    end

    context "when ressurector is disabled" do
      before do
        allow(described_class).to receive(:ressurector_disabled?).and_return(true)
      end

      it { is_expected.to eq(nil) }
    end

    context "when reaper is disabled?" do
      before do
        allow(described_class).to receive(:reaper_disabled?).and_return(true)
      end

      it { is_expected.to eq(nil) }
    end

    context "when both ressurector and reaper are enabled?" do
      it { is_expected.to eq(task) }

      it "logs a start message" do
        start

        expect(described_class).to have_received(:log_info).with("Starting Reaper Ressurector")
      end

      it "executes the task" do
        start

        expect(task).to have_received(:execute)
      end
    end
  end

  describe ".ressurector_disabled?" do
    subject(:ressurector_disabled) { described_class.ressurector_disabled? }

    context "when ressurector is disabled" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper_ressurector_enabled: false, &example)
      end

      it { is_expected.to eq(true) }
    end

    context "when ressurector is enabled" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper_ressurector_enabled: true, &example)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe ".ressurector_enabled?" do
    subject(:ressurector_enabled) { described_class.ressurector_enabled? }

    context "when ressurector is disabled" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper_ressurector_enabled: false, &example)
      end

      it { is_expected.to eq(false) }
    end

    context "when ressurector is enabled" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper_ressurector_enabled: true, &example)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe ".reaper_enabled?" do
    subject(:reaper_enabled) { described_class.reaper_enabled? }

    context "when SidekiqUniqueJobs.config.reaper = :lua" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :lua, &example)
      end

      it { is_expected.to eq(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :ruby" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :ruby, &example)
      end

      it { is_expected.to eq(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :none" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :none, &example)
      end

      it { is_expected.to eq(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = nil" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: nil, &example)
      end

      it { is_expected.to eq(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = false" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: false, &example)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe ".reaper_disabled?" do
    subject(:disabled) { described_class.reaper_disabled? }

    context "when SidekiqUniqueJobs.config.reaper = :lua" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :lua, &example)
      end

      it { is_expected.to eq(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :ruby" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :ruby, &example)
      end

      it { is_expected.to eq(false) }
    end

    context "when SidekiqUniqueJobs.config.reaper = :none" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: :none, &example)
      end

      it { is_expected.to eq(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = nil" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: nil, &example)
      end

      it { is_expected.to eq(true) }
    end

    context "when SidekiqUniqueJobs.config.reaper = false" do
      around do |example|
        SidekiqUniqueJobs.use_config(reaper: false, &example)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe ".reaper_registered?" do
    subject(:reaper_registered) { described_class.reaper_registered? }

    context "when registered" do
      before { SidekiqUniqueJobs::Orphans::Manager.register_reaper_process }

      it { is_expected.to eq(true) }
    end

    context "when unregistered" do
      it { is_expected.to eq(false) }
    end
  end

  describe ".timer_task_options" do
    subject(:timer_task_options) { described_class.timer_task_options }

    let(:expected_options) do
      { run_now: false,
        execution_interval: SidekiqUniqueJobs.config.reaper_ressurector_interval }
    end

    it { is_expected.to eq(expected_options) }
  end

  describe ".reaper_ressurector_interval" do
    subject(:reaper_ressurector_interval) { described_class.reaper_ressurector_interval }

    it { is_expected.to eq(SidekiqUniqueJobs.config.reaper_ressurector_interval) }
  end

  describe ".restart_if_dead" do
    subject(:restart_if_dead) { described_class.restart_if_dead }

    before do
      allow(manager).to receive(:start).and_return(task)
    end

    context "when reaper registered" do
      before do
        allow(described_class).to receive(:reaper_registered?).and_return(true)
      end

      it "does not start new reaper" do
        restart_if_dead

        expect(manager).not_to have_received(:start)
      end
    end

    context "when reaper not registered" do
      before do
        allow(described_class).to receive(:reaper_registered?).and_return(false)
      end

      it "starts new manager" do
        restart_if_dead

        expect(manager).to have_received(:start)
      end
    end
  end

  describe ".logging_context" do
    subject(:logging_context) { described_class.logging_context }

    before do
      allow(described_class).to receive(:logger_context_hash?).and_return(requires_hash_context)
    end

    context "when logger_context_hash?" do
      let(:requires_hash_context) { true }

      it { is_expected.to eq("uniquejobs" => "reaper-ressurector") }
    end

    context "when not logger_context_hash?" do
      let(:requires_hash_context) { false }

      it { is_expected.to eq("uniquejobs=reaper-ressurector") }
    end
  end
end
