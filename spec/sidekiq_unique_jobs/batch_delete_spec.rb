# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::BatchDelete do
  let(:digests) { [] }

  describe ".call" do
    subject(:call) { described_class.call(digests) }

    before do
      10.times do
        digest = "uniquejobs:#{SecureRandom.hex}"
        SidekiqUniqueJobs::Lock.create(digest, SecureRandom.hex(12))
        digests << digest
      end
    end

    it "deletes all digests and their LOCKED hashes" do
      expect(unique_keys.size).to eq(10)

      call

      expect(unique_keys).to eq([])
    end
  end
end
