# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Unlockable do
  def item_with_digest
    SidekiqUniqueJobs::UniqueArgs.digest(item)
    item
  end
  let(:item) do
    { 'class' => MyUniqueJob,
      'queue' => 'customqueue',
      'args' => [1, 2] }
  end

  let(:unique_digest) { item_with_digest[SidekiqUniqueJobs::UNIQUE_DIGEST_KEY] }
  describe '.unlock_by_key' do
    before do
    end

    specify do
      expect(SidekiqUniqueJobs::Util.keys.count).to eq(0)
      jid = Sidekiq::Client.push(item_with_digest)

      expect(SidekiqUniqueJobs::Util.keys.count).to eq(1)
      expect(SidekiqUniqueJobs::Util.keys).to match_array([unique_digest])
      expect(SidekiqUniqueJobs::Util.unique_key(jid)).to eq(unique_digest)

      described_class.unlock_by_key(
        unique_digest,
        jid,
      )

      expect(SidekiqUniqueJobs::Util.keys.count).to eq(0)
      expect(SidekiqUniqueJobs::Util.keys).not_to match_array([unique_digest])
      expect(SidekiqUniqueJobs::Util.unique_key(jid)).to eq(nil)
    end
  end
end
