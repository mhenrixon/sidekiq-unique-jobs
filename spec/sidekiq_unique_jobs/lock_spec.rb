# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Lock do
  subject(:entity) { described_class.new(key) }

  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest) { SecureRandom.hex(12) }
  let(:job_id) { SecureRandom.hex(12) }
  let(:expected_string) do
    <<~MESSAGE
      Lock status for #{digest}

                value:\s
                 info: []
          queued_jids: []
          primed_jids: []
          locked_jids: []
           changelogs: []
    MESSAGE
  end

  its(:digest)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::String) }
  its(:queued)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::List) }
  its(:primed)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::List) }
  its(:locked)  { is_expected.to be_a(SidekiqUniqueJobs::Redis::Hash) }
  its(:inspect) { is_expected.to eq(expected_string) }
  its(:to_s)    { is_expected.to eq(expected_string) }

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

  describe "#changelogs" do
    subject(:changelogs) { entity.changelogs }

    context "when no changelogs exist" do
      it { is_expected.to match_array([]) }
    end

    context "when changelogs exist" do
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
