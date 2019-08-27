# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Lock::Validator do
  let(:validator) { described_class.new(options) }
  let(:options) do
    {
      "lock" => "until_executed",
      "lock_limit" => 1,
      "lock_timeout" => 0,
      "lock_ttl" => 100,
      "lock_info" => false,
      "on_conflict" => "replace",
    }
  end

  it { expect(true).to eq(true) }

  # describe ".validate" do
  #   subject(:validate) { described_class.validate({}) }
  # end

  # describe "#validate" do
  #   subject(:validate) { validator.validate }
  # end
end
