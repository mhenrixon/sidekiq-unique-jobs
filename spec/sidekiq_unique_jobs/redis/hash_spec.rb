# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Redis::Hash do
  let(:entity) { described_class.new(key) }
  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest) { "digest:#{SecureRandom.hex(12)}" }
  let(:job_id) { SecureRandom.hex(12) }

  let!(:now_f) { SidekiqUniqueJobs.now_f }

  describe "#entries" do
    subject(:entries) { entity.entries(with_values: with_values) }

    let(:with_values) { nil }

    context "without entries" do
      it { is_expected.to match_array([]) }
    end

    context "with entries" do
      before { hset(digest, job_id, now_f) }

      context "when with_values: false" do
        let(:with_values) { false }

        it { is_expected.to match_array([job_id]) }
      end

      context "when with_values: true" do
        let(:with_values) { true }

        it { is_expected.to eq(job_id => now_f.to_s) }
      end
    end
  end

  describe "#count" do
    subject(:count) { entity.count }

    context "without entries" do
      it { is_expected.to be == 0 }
    end

    context "with entries" do
      before { hset(digest, job_id, now_f) }

      it { is_expected.to be == 1 }
    end
  end
end
