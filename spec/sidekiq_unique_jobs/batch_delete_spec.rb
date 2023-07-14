# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::BatchDelete do
  let(:digests) { [] }
  let(:locks)   { [] }

  describe ".call" do
    subject(:call) { described_class.call(digests) }

    before do
      10.times do |_n|
        digest   = SecureRandom.hex
        lock     = SidekiqUniqueJobs::Lock.create(digest, digest)

        lock.queue(digest)
        lock.prime(digest)

        digests << digest
        locks << lock
      end
    end

    it "deletes all digests (locked, primed, queued and run keys)" do
      call

      locks.all? do |lock|
        expect(lock.all_jids).to be_empty
        expect(unique_keys).to be_empty
      end
    end
  end
end
