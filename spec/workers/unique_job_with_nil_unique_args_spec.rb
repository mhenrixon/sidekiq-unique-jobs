# frozen_string_literal: true

RSpec.describe UniqueJobWithNilUniqueArgs do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => true,
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
        "lock_args_method" => :unique_args,
      }
    end
  end

  it_behaves_like "a performing worker", splat_arguments: false do
    let(:args) { ["argument one", "two", "three"] }
  end

  describe ".unique_args" do
    subject { described_class.unique_args(args) }

    let(:args) { ["argument one", "two", "three"] }

    it { is_expected.to be_nil }
  end
end
