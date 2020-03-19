# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Unlockable do
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest)       { item["digest"] }
  let(:lock)         { SidekiqUniqueJobs::Lock.new(key) }
  let(:args)         { [1, 2] }
  let(:jid)          { SecureRandom.hex(16) }
  let(:queue)        { "customqueue" }
  let(:lock_ttl)     { 7_200 }
  let(:lock_timeout) { 0 }
  let(:worker_class) { MyUniqueJob }
  let(:item) do
    SidekiqUniqueJobs::Job.prepare(
      "class" => worker_class,
      "queue" => queue,
      "args" => args,
      "jid" => jid,
    )
  end

  describe ".unlock" do
    subject(:unlock) { described_class.unlock(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect { unlock }.to change { unique_keys.size }.by(1)
      # TODO: Verify why these are failing
      # expect(key.locked).to have_ttl(7_200)
      # expect(key.info).to have_ttl(7_200)
      # expect(key.digest).to have_ttl(7_200)
    end
  end

  describe ".delete" do
    subject(:delete) { described_class.delete(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect { delete }.to change { unique_keys.size }.by(0)

      # TODO: Verify why these are failing
      # expect(key.locked).to have_ttl(7_200)
      # expect(key.info).to have_ttl(7_200)
      # expect(key.digest).to have_ttl(7_200)
    end
  end

  describe ".delete!" do
    subject(:delete!) { described_class.delete!(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect { delete! }.to change { unique_keys.size }.by(-3)
      expect(digest).to have_ttl(-2)
    end
  end
end
