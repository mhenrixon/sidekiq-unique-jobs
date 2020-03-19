# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Config do
  describe ".locks" do
    let(:config) { described_class.default }

    context "when using default config" do
      it "falls back on default option" do
        expect(config.locks).to eq(SidekiqUniqueJobs::Config::LOCKS)
      end
    end

    context "when trying to add an already existing lock" do
      it "raises an DuplicateLock exception" do
        name = "while_executing"
        expect do
          config.add_lock name, Class
        end.to raise_exception(SidekiqUniqueJobs::DuplicateLock, /#{name} already defined/)
      end
    end

    context "when adding a new lock" do
      it "preserves it in the config instance" do
        name = "some_lock"
        klass = Class

        original_locks_id = config.locks.object_id
        config.add_lock name, klass

        expect(config.locks.frozen?).to be(true)
        expect(config.locks.keys).to include(:some_lock)
        expect(config.locks.fetch(:some_lock)).to eq(Class)
        expect(config.locks.object_id).not_to eq(original_locks_id)
      end

      it "accepts as many locks as you want" do
        stub_const("CustomLock1", Class.new)
        stub_const("CustomLock2", Class.new)

        config.add_lock :custom_lock1, CustomLock1
        config.add_lock :custom_lock2, CustomLock2

        expect(config.locks.frozen?).to be(true)
        expect(config.locks.keys).to include(:custom_lock1, :custom_lock2)
        expect(config.locks.fetch(:custom_lock1)).to eq(CustomLock1)
        expect(config.locks.fetch(:custom_lock2)).to eq(CustomLock2)
      end
    end
  end

  describe ".strategies" do
    let(:config) { described_class.default }

    context "when using default config" do
      it "falls back on default option" do
        expect(config.strategies).to eq(SidekiqUniqueJobs::Config::STRATEGIES)
      end
    end

    context "when trying to add an already existing lock" do
      it "raises an DuplicateStrategy exception" do
        name = "log"
        expect do
          config.add_strategy name, Class
        end.to raise_exception(SidekiqUniqueJobs::DuplicateStrategy, /#{name} already defined/)
      end
    end

    context "when adding a new strategy" do
      it "preserves it in the config instance" do
        name = "some_strategy"
        klass = Class

        original_strategies_id = config.strategies.object_id
        config.add_strategy name, klass

        expect(config.strategies.frozen?).to be(true)
        expect(config.strategies.keys).to include(:some_strategy)
        expect(config.strategies.fetch(:some_strategy)).to eq(Class)
        expect(config.strategies.object_id).not_to eq(original_strategies_id)
      end

      it "accepts as many strategies as you want" do
        stub_const("CustomStrategy1", Class.new)
        stub_const("CustomStrategy2", Class.new)

        config.add_strategy "custom_strategy1", CustomStrategy1
        config.add_strategy :custom_strategy2, CustomStrategy2

        expect(config.strategies.frozen?).to be(true)
        expect(config.strategies.keys).to include(:custom_strategy1, :custom_strategy2)
        expect(config.strategies.fetch(:custom_strategy1)).to eq(CustomStrategy1)
        expect(config.strategies.fetch(:custom_strategy2)).to eq(CustomStrategy2)
      end
    end
  end

  # Test backported from spec/unit/on_conflict_spec.rb
  describe "::STRATEGIES" do
    subject { described_class::STRATEGIES }

    let(:expected) do
      {
        log: SidekiqUniqueJobs::OnConflict::Log,
        raise: SidekiqUniqueJobs::OnConflict::Raise,
        reject: SidekiqUniqueJobs::OnConflict::Reject,
        replace: SidekiqUniqueJobs::OnConflict::Replace,
        reschedule: SidekiqUniqueJobs::OnConflict::Reschedule,
      }
    end

    it { is_expected.to eq(expected) }
  end
end
