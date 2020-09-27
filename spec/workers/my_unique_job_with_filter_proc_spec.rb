# frozen_string_literal: true

RSpec.describe MyUniqueJobWithFilterProc do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => true,
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { ["one", { "type" => "unique", "id" => 2 }] }
  end

  describe "lock_args" do
    subject(:lock_args) { described_class.get_sidekiq_options["lock_args"].call(args) }

    let(:args) { ["one", { "type" => "unique", "id" => 2 }] }

    it { is_expected.to eq(%w[one unique]) }
  end
end
