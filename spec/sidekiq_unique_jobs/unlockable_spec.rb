# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Unlockable do
  def item_with_digest
    SidekiqUniqueJobs::UniqueArgs.digest(item)
    item
  end

  let(:item) do
    { "class" => MyUniqueJob,
      "queue" => "customqueue",
      "args" => [1, 2] }
  end

  let(:digest) { item_with_digest[SidekiqUniqueJobs::UNIQUE_DIGEST] }

  describe ".unlock" do
    subject(:unlock) { described_class.unlock(item_with_digest) }

    specify do
      expect(unique_keys.size).to eq(0)

      push_item(item_with_digest)

      expect(unique_keys.size).to be >= 2

      unlock

      expect(unique_keys.size).to be >= 2
      expect(ttl(digest)).to eq(7200)
    end
  end

  describe ".delete" do
    subject(:delete) { described_class.delete(item_with_digest) }

    specify do
      expect(unique_keys.size).to eq(0)
      push_item(item_with_digest)

      expect(unique_keys.size).to be >= 2

      delete

      # This lock has expiration so won't be unlocked
      expect(unique_keys.size).to be >= 2
    end
  end
end
