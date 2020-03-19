# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Unlockable do
  let(:digest)       { SecureRandom.hex(16) }
  let(:args)         { [1, 2] }
  let(:queue)        { "customqueue" }
  let(:lock_ttl)     { 7_200 }
  let(:lock_timeout) { 0 }
  let(:worker_class) { MyUniqueJob }
  let(:item) do
    { "class" => worker_class,
      "queue" => queue,
      "unique_args" => args,
      "unique_digest" => digest,
      "args" => args,
      "lock_ttl" => lock_ttl,
      "lock_timeout" => lock_timeout }
  end

  describe ".unlock" do
    subject(:unlock) { described_class.unlock(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect(digest).to have_ttl(7_200)
      expect { unlock }.not_to change { unique_keys.size }
      expect(digest).to have_ttl(7_200)
    end
  end

  describe ".delete" do
    subject(:delete) { described_class.delete(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect(digest).to have_ttl(7_200)
      expect { delete }.not_to change { unique_keys.size }
      expect(digest).to have_ttl(7_200)
    end
  end
end
