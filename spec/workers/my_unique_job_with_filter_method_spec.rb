# frozen_string_literal: true

RSpec.describe MyUniqueJobWithFilterMethod do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => true,
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
        "lock_args" => :lock_args,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { ["hundred", { "type" => "extremely unique", "id" => 44 }] }
  end

  describe ".lock_args" do
    subject { described_class.lock_args(args) }

    let(:args) { ["two", { "type" => "very unique", "id" => 4 }] }

    it { is_expected.to eq(["two", "very unique"]) }
  end
end
