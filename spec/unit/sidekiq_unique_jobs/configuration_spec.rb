# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Configuration do
  describe ".locks" do
    let(:config) { described_class.new }

    context "when using default configuration" do
      it "falls back on default option" do
        expect(config.locks).to eq(SidekiqUniqueJobs::Configuration::DEFAULT_LOCKS)
      end
    end

    context "when trying to add an already existing lock" do
      it "raises an ArgumentError exception" do
        name = "while_executing"
        expect do
          config.add_lock name, Class
        end.to raise_exception(ArgumentError, /#{name} already defined/)
      end
    end

    context "when adding a new lock" do
      it "preserves it in the configuration instance" do
        name = "some_lock"
        klass = Class

        original_locks_id = config.locks.object_id
        config.add_lock name, klass

        aggregate_failures do
          expect(config.locks.frozen?).to be(true)
          expect(config.locks.keys).to include(:some_lock)
          expect(config.locks.fetch(:some_lock)).to eq(Class)
          expect(config.locks.object_id).not_to eq(original_locks_id)
        end
      end

      it "accepts as many locks as you want" do
        CustomLock1 = Class.new
        CustomLock2 = Class.new

        config.add_lock :custom_lock1, CustomLock1
        config.add_lock :custom_lock2, CustomLock2

        aggregate_failures do
          expect(config.locks.frozen?).to be(true)
          expect(config.locks.keys).to include(:custom_lock1, :custom_lock2)
          expect(config.locks.fetch(:custom_lock1)).to eq(CustomLock1)
          expect(config.locks.fetch(:custom_lock2)).to eq(CustomLock2)
        end
      end
    end
  end
end
