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
  let(:job_class)    { MyUniqueJob }
  let(:item) do
    SidekiqUniqueJobs::Job.prepare(
      "class" => job_class,
      "queue" => queue,
      "args" => args,
      "lock_ttl" => lock_ttl,
      "jid" => jid,
    )
  end

  describe ".unlock" do
    subject(:unlock) { described_class.unlock(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect { unlock }.to change { unique_keys.size }.by(-2)
    end
  end

  describe ".unlock!" do
    subject(:unlock!) { described_class.unlock!(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect { unlock! }.to change { unique_keys.size }.by(-2)
    end
  end

  describe ".delete" do
    subject(:delete) { described_class.delete(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect { delete }.not_to change { unique_keys.size }
    end
  end

  describe ".delete!" do
    subject(:delete!) { described_class.delete!(item) }

    specify do
      expect { push_item(item) }.to change { unique_keys.size }.by(3)
      expect { delete! }.to change { unique_keys.size }.by(-3)
    end
  end
end
