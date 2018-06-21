# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Scripts, redis: :redis do
  subject { SidekiqUniqueJobs::Scripts }

  it { is_expected.to respond_to(:call).with(3).arguments }
  it { is_expected.to respond_to(:redis).with(1).arguments }
  it { is_expected.to respond_to(:script_source).with(1).arguments }
  it { is_expected.to respond_to(:script_path).with(1).arguments }

  describe '.call' do
    subject(:call) { described_class.call(script_name, nil, options) }

    let(:jid)           { 'abcefab' }
    let(:unique_key)    { 'uniquejobs:abcefab' }
    let(:max_lock_time) { 1 }
    let(:options)       { { keys: [unique_key], argv: [jid, max_lock_time] } }
    let(:scriptsha)     { 'abcdefab' }
    let(:script_name)   { :acquire_lock }
    let(:error_message) { 'Some interesting error' }

    context 'when conn.evalsha raises Redis::CommandError' do
      before do
        call_count = 0
        allow(described_class).to receive(:execute_script).with(script_name, nil, options) do
          call_count += 1
          (call_count == 1) ? raise(Redis::CommandError, error_message) : 1
        end
      end

      specify do
        expect(described_class::SCRIPT_SHAS).not_to receive(:delete).with(script_name)
        expect(described_class).to receive(:execute_script).with(script_name, nil, options).once
        expect { call }.to raise_error(
          SidekiqUniqueJobs::ScriptError,
          "Problem compiling #{script_name}. Message: Some interesting error",
        )
      end

      context 'when error message is No matching script' do
        let(:error_message) { 'NOSCRIPT No matching script. Please use EVAL.' }

        specify do
          expect(described_class::SCRIPT_SHAS).to receive(:delete).with(script_name)
          expect(described_class).to receive(:execute_script).with(script_name, nil, options).twice
          expect { call }.not_to raise_error
        end
      end
    end
  end
end
