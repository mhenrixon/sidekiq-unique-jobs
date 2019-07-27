# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Lock::ServerValidator do
  let(:lock_config) do
    SidekiqUniqueJobs::LockConfig.new(
      "lock" => lock_class,
      "lock_limit" => lock_limit,
      "lock_timeout" => lock_timeout,
      "lock_ttl" => lock_ttl,
      "lock_info" => lock_info,
      "on_conflict" => on_conflict,
    )
  end

  let(:lock_class)   { :until_executed }
  let(:lock_limit)   { 1 }
  let(:lock_timeout) { 10 }
  let(:lock_ttl)     { 100 }
  let(:lock_info)    { false }
  let(:on_conflict)  { :replace }

  describe ".validate" do
    subject(:validate) { described_class.validate(lock_config) }

    context "when on_conflict is replace" do
      let(:on_conflict) { :replace }

      it "adds an entry in the errors hash" do
        validate
        expect(lock_config.errors[:on_server_conflict])
          .to eq("#{on_conflict} is incompatible with the server process")
      end
    end
  end
end
