# frozen_string_literal: true

require "spec_helper"
RSpec.describe SimpleWorker do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "queue" => :default,
        "retry" => true,
        "lock" => :until_executed,
      }
    end
  end

  it_behaves_like "a performing worker", splat_arguments: false do
    let(:args) { ["one", "type" => "unique", "id" => 2] }
  end

  describe "unique_args" do
    subject do
      described_class.get_sidekiq_options["unique_args"].call(args, a_hash_including("jid": "abc"))
    end

    let(:args) { ["unique", "type" => "unique", "id" => 2] }

    it { is_expected.to eq(["unique"]) }
  end
end
