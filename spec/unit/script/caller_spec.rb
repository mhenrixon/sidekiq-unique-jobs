# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Script::Caller, redis: :redis do
  subject { described_class }

  it { is_expected.to respond_to(:call_script).with(3).arguments }

  describe ".call_script" do
    subject(:call_script) { described_class.call_script(script_name, options[:keys], options[:argv]) }

    let(:jid)           { "abcefab" }
    let(:unique_key)    { "uniquejobs:abcefab" }
    let(:max_lock_time) { 1 }
    let(:options)       { { keys: [unique_key], argv: [jid, max_lock_time] } }
    let(:scriptsha)     { "abcdefab" }
    let(:script_name)   { :acquire_lock }
    let(:error_message) { "Some interesting error" }

    before do
      allow(SidekiqUniqueJobs::Script).to receive(:call).with(script_name, nil, keys: options[:keys], argv: options[:argv])
    end

    it "delegates to Script.call" do
      call_script

      expect(SidekiqUniqueJobs::Script).to have_received(:call).with(script_name, nil, keys: options[:keys], argv: options[:argv])
    end
  end
end
