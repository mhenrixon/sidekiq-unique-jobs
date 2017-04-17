# frozen_string_literal: true

require 'spec_helper'
RSpec.describe SidekiqUniqueJobs::Scripts do
  MD5_DIGEST ||= 'unique'
  UNIQUE_KEY ||= 'uniquejobs:unique'
  JID ||= 'fuckit'
  ANOTHER_JID ||= 'anotherjid'

  context 'class methods' do
    subject { SidekiqUniqueJobs::Scripts }

    it { is_expected.to respond_to(:call).with(3).arguments }
    it { is_expected.to respond_to(:logger) }
    it { is_expected.to respond_to(:connection).with(1).arguments }
    it { is_expected.to respond_to(:script_source).with(1).arguments }
    it { is_expected.to respond_to(:script_path).with(1).arguments }

    describe '.logger' do
      its(:logger) { is_expected.to eq(Sidekiq.logger) }
    end

    describe '.call' do
      let(:jid) { 'abcefab' }
      let(:unique_key) { 'uniquejobs:abcefab' }
      let(:max_lock_time) { 1 }
      let(:options) { { keys: [unique_key], argv: [jid, max_lock_time] } }
      let(:scriptsha) { 'abcdefab' }
      let(:script_name) { :acquire_lock }
      let(:error_message) { 'Some interesting error' }

      subject { described_class.call(script_name, nil, options) }

      context 'when redis.evalsha raises Redis::CommandError' do
        before do
          call_count = 0
          allow(described_class).to receive(:internal_call).with(script_name, nil, options) do
            call_count += 1
            (call_count == 1) ? raise(Redis::CommandError, error_message) : 1
          end
        end

        specify do
          expect(described_class::SCRIPT_SHAS).not_to receive(:delete).with(script_name)
          expect(described_class).to receive(:internal_call).with(script_name, nil, options).once
          expect { subject }.to raise_error(
            SidekiqUniqueJobs::ScriptError,
            "Problem compiling #{script_name}. Invalid LUA syntax?",
          )
        end

        context 'when error message is No matching script' do
          let(:error_message) { 'NOSCRIPT No matching script. Please use EVAL.' }

          specify do
            expect(described_class::SCRIPT_SHAS).to receive(:delete).with(script_name)
            expect(described_class).to receive(:internal_call).with(script_name, nil, options).twice
            expect { subject }.not_to raise_error
          end
        end
      end
    end
  end
end
