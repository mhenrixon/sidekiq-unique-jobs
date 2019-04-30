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
  let(:key)           { SidekiqUniqueJobs::Key.new(unique_digest) }
  let(:expected_keys) { [key.lock_key, key.wait] }

  describe ".keys" do
    subject(:keys) { described_class.keys }
    context "with existing lock" do
      before do
        lock.lock
      end

      it { is_expected.to match_array(expected_keys) }
    end
  end

  describe ".del" do
    subject(:del) { described_class.del(pattern, 100) }

    before do
      lock.lock
    end

    context "when pattern is a wildcard" do
      let(:pattern) { described_class::SCAN_PATTERN }

      it "deletes the matching keys" do
        expect { del }.to change { described_class.keys }.to([])
        expect(del).to eq(2)
      end
    end

    context "when pattern is a specific key" do
      let(:pattern) { key.lock_key }

      it "deletes the matching keys" do
        expect { del }.to change { described_class.keys }.to([])
        expect(del).to eq(2)
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
