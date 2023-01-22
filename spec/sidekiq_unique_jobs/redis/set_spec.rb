# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Redis::Set do
  let(:entity) { described_class.new(key.digest) }
  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest) { "digest:#{SecureRandom.hex(12)}" }
  let(:job_id) { SecureRandom.hex(12) }

  describe "#entries" do
    subject(:entries) { entity.entries }

    context "without entries" do
      it { is_expected.to match_array([]) }
    end

    context "with entries" do
      before { sadd(digest, job_id) }

      it { is_expected.to match_array([job_id]) }
    end
  end

  describe "#count" do
    subject(:count) { entity.count }

    context "without entries" do
      it { is_expected.to be == 0 }
    end

    context "with entries" do
      before { sadd(digest, job_id) }

      it { is_expected.to be == 1 }
    end
  end
end
