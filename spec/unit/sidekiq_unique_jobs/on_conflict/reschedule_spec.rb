# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::OnConflict::Reschedule do
  let(:strategy)      { described_class.new(item) }
  let(:unique_digest) { "uniquejobs:random-digest-value" }
  let(:item) do
    { "class" => UniqueJobOnConflictReschedule,
      "unique_digest" => unique_digest,
      "args" => [1, 2] }
  end

  describe "#call" do
    let(:call) { strategy.call }

    it do
      expect { call }.to change { schedule_count }.by(1)
    end
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to eq(false) }
  end
end
