require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Redis::String do
  let(:entity) { described_class.new(key) }
  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest) { SecureRandom.hex(12) }
  let(:job_id) { SecureRandom.hex(12) }

  describe "#count" do
    subject(:count) { entity.count }

    context "without entries" do
      it { is_expected.to be == 0 }
    end

    context "with entries" do
      before { set(digest, job_id) }

      it { is_expected.to be == 1 }
    end
  end

  describe "#value" do
    subject(:value) { entity.value }

    context "without entries" do
      it { is_expected.to be == nil }
    end

    context "with entries" do
      before { set(digest, job_id) }

      it { is_expected.to be == job_id }
    end
  end
end
