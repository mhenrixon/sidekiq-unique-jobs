# frozen_string_literal: true

require "spec_helper"
RSpec.describe MyUniqueJobWithFilterMethod do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "backtrace" => true,
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
        "unique_args" => :filtered_args,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { ["hundred", "type" => "extremely unique", "id" => 44] }
  end

  describe ".filtered_args" do
    subject { described_class.filtered_args(args, a_hash_including("jid": "abc")) }

    let(:args) { ["two", "type" => "very unique", "id" => 4] }

    it { is_expected.to eq(["two", "very unique"]) }
  end
end
