# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Redis::Entity do
  subject(:entity) { described_class.new(key) }

  let(:key)        { "digest" }

  its(:count) { is_expected.to eq(0) }

  describe "#exist?" do
    subject(:exist?) { entity.exist? }

    context "when key exists" do
      before do
        set(key, "bogus")
      end

      it { is_expected.to eq(true) }
    end

    context "when key does not exist" do
      it { is_expected.to eq(false) }
    end
  end
end
