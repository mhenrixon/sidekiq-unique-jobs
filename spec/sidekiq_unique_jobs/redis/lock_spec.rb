# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Redis::Lock do
  let(:entity) { described_class.new(key) }
  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest) { SecureRandom.hex(12) }
  let(:job_id) { SecureRandom.hex(12) }

  describe "#all_jids" do
    subject(:all_jids) { entity.all_jids }

    context "when no locks exist" do
      it { is_expected.to match_array([]) }
    end

    context "when locks exists" do
      before { simulate_lock(key, job_id) }

      it { is_expected.to match_array([job_id]) }
    end
  end

  describe "#changelog_entries" do
    subject(:changelog_entries) { entity.changelog_entries }

    context "when no changelog_entries exist" do
      it { is_expected.to match_array([]) }
    end

    context "when changelog_entries exist" do
      before { simulate_lock(key, job_id) }

      let(:locked_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Locked",
          "script" => "lock.lua",
          "time" => kind_of(Float),
        }
      end
      let(:queued_entry) do
        {
          "digest" => digest,
          "job_id" => job_id,
          "message" => "Queued",
          "script" => "queue.lua",
          "time" => kind_of(Float),
        }
      end

      it { is_expected.to match_array([locked_entry, queued_entry]) }
    end
  end
end
