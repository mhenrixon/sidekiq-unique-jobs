# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::Util, redis: :redis do
  let(:item_hash) do
    {
      "class" => "MyUniqueJob",
      "args" => [[1, 2]],
      "at" => 1_492_341_850.358196,
      "retry" => true,
      "queue" => "customqueue",
      "lock" => :until_executed,
      "lock_expiration" => 7200,
      "retry_count" => 10,
      "jid" => jid,
      "created_at" => 1_492_341_790.358217,
    }
  end

  let!(:item) do
    my_item = item_hash.dup
    SidekiqUniqueJobs::UniqueArgs.new(my_item).unique_digest
    my_item
  end

  let(:unique_digest) { item["unique_digest"] }
  let(:jid)           { "e3049b05b0bd9c809182bbe0" }
  let(:lock)          { SidekiqUniqueJobs::Locksmith.new(item) }
  let(:expected_keys) do
    %W[
      #{unique_digest}:EXISTS
      #{unique_digest}:GRABBED
    ]
  end

  shared_context "with an old lock" do
    let!(:old_lock) do
      SidekiqUniqueJobs::Scripts.call(
        :acquire_lock,
        nil,
        keys: [unique_digest],
        argv: [jid, 7200],
      )
    end

    specify { expect(old_lock).to eq(1) }
    specify { expect(described_class.keys).to include(unique_digest) }
  end

  describe ".keys" do
    subject(:keys) { described_class.keys }

    context "when old lock exists" do
      include_context "with an old lock"

      it { is_expected.to match_array([unique_digest]) }
    end

    context "when new lock exists" do
      before do
        lock.lock(0)
      end

      it { is_expected.to match_array(expected_keys) }
    end
  end

  describe ".del" do
    subject(:del) { described_class.del(pattern, 100) }

    context "when an old lock exists" do
      include_context "with an old lock"

      it { expect(described_class.keys).to match_array([unique_digest]) }

      context "when pattern is a wildcard" do
        let(:pattern) { described_class::SCAN_PATTERN }

        it { is_expected.to eq(1) }
        it { expect { del }.to change { described_class.keys }.to([]) }
      end

      context "when pattern is a specific key" do
        let(:pattern) { unique_digest }

        it { is_expected.to eq(1) }
        it { expect { del }.to change { described_class.keys }.to([]) }
      end
    end

    context "when a new lock exists" do
      before do
        lock.lock(0)
      end

      after { lock.delete }

      it { expect(described_class.keys).to match_array(expected_keys) }

      context "when pattern is a wildcard" do
        let(:pattern) { described_class::SCAN_PATTERN }

        it { is_expected.to eq(2) }
        it { expect { del }.to change { described_class.keys }.to([]) }
      end

      context "when pattern is a specific key" do
        let(:pattern) { unique_digest }

        it { is_expected.to eq(2) }
        it { expect { del }.to change { described_class.keys }.to([]) }
      end
    end
  end

  describe ".prefix" do
    subject(:prefix) { described_class.send(:prefix, key) }

    let(:key) { "key" }

    context "when prefix is configured" do
      before { allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return("test-uniqueness") }

      it { is_expected.to eq("test-uniqueness:key") }

      context "when key is already prefixed" do
        let(:key) { "test-uniqueness:key" }

        it { is_expected.to eq("test-uniqueness:key") }
      end
    end

    context "when .unique_prefix is nil?" do
      before { allow(SidekiqUniqueJobs.config).to receive(:unique_prefix).and_return(nil) }

      it { is_expected.to eq("key") }
    end
  end
end
