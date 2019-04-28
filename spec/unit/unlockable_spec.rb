# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Unlockable, redis: :redis do
  def item_with_digest
    SidekiqUniqueJobs::UniqueArgs.digest(item)
    item
  end

  let(:item) do
    { "class" => MyUniqueJob,
      "queue" => "customqueue",
      "args" => [1, 2] }
  end

  let(:unique_digest) { item_with_digest[SidekiqUniqueJobs::UNIQUE_DIGEST_KEY] }

  describe ".unlock" do
    subject(:unlock) { described_class.unlock(item_with_digest) }

    specify do
      expect(unique_keys.size).to eq(0)
      push_item(item_with_digest)

      expect(unique_keys.size).to eq(1)

      unlock
      expect(unique_keys.size).to eq(1)
    end
  end

  describe ".delete" do
    subject(:delete) { described_class.delete(item_with_digest) }

    specify do
      expect(unique_keys.size).to eq(0)
      push_item(item_with_digest)

      expect(unique_keys.size).to eq(1)

      delete

      expect(unique_keys.size).to eq(1)
    end
  end
end
