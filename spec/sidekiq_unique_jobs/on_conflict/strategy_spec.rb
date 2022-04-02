# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::OnConflict::Strategy do
  let(:strategy)      { described_class.new(item) }
  let(:unique_digest) { "uniquejobs:56c68cab5038eb57959538866377560d" }
  let(:item) do
    { "lock_digest" => unique_digest, "queue" => :customqueue }
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to be(false) }
  end

  describe "#call" do
    let(:call) { strategy.call }

    it "raises an error" do
      expect { call }.to raise_error(NotImplementedError, "needs to be implemented in child class")
    end
  end
end
