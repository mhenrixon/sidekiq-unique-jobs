# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Script do
  subject { described_class }

  it { is_expected.to respond_to(:call).with(2).arguments.and_keywords(:keys, :argv) }
  it { is_expected.to respond_to(:redis).with(1).arguments }
  it { is_expected.to respond_to(:script_source).with(1).arguments }
  it { is_expected.to respond_to(:script_path).with(1).arguments }

  describe ".call" do
    subject(:call) { described_class.call(script_name, redis, script_arguments) }

    let(:jid)              { "abcefab" }
    let(:unique_key)       { "uniquejobs:abcefab" }
    let(:max_lock_time)    { 1 }
    let(:keys)             { [unique_key] }
    let(:argv)             { [jid, max_lock_time] }
    let(:redis)            { Redis.new }
    let(:scriptsha)        { "abcdefab" }
    let(:script_arguments) { { keys: keys, argv: argv } }
    let(:script_name)      { :lock }
    let(:error_message) do
      <<~ERR
        ERR Error running script (call to f_178d75adaa46af3d8237cfd067c9fdff7b9d504f): [string "func definition"]:5: attempt to compare nil with number
      ERR
    end

    context "when conn.evalsha raises Redis::CommandError" do
      before do
        call_count = 0
        allow(described_class).to receive(:execute_script).with(script_name, redis, keys, argv) do
          call_count += 1
          (call_count == 1) ? raise(Redis::CommandError, error_message) : 1
        end

        allow(described_class::SCRIPT_SHAS).to receive(:delete)
      end

      specify do
        begin
          call
        rescue SidekiqUniqueJobs::ScriptError => ex
          expect(ex.message).to start_with("attempt to compare nil with number")
          expect(ex.message).to include("3: local queued    = KEYS[2]")
          expect(ex.message).to include("4: local primed    = KEYS[3]")
          expect(ex.message).to include("=> 5: local locked    = KEYS[4]")
          expect(ex.message).to include("6: local changelog = KEYS[5]")
          expect(ex.message).to include("7: local digests   = KEYS[6]")

          expect(ex.backtrace.first).to match(%r{lib/sidekiq_unique_jobs/lua/lock.lua:5})
          expect(ex.backtrace[1]).to match(/script.rb/)
        end

        expect(described_class::SCRIPT_SHAS).not_to have_received(:delete).with(script_name)
        expect(described_class).to have_received(:execute_script).with(script_name, redis, keys, argv).once
      end

      context "when error message is No matching script" do
        let(:error_message) { "NOSCRIPT No matching script. Please use EVAL." }

        specify do
          expect { call }.not_to raise_error

          expect(described_class::SCRIPT_SHAS).to have_received(:delete).with(script_name)
          expect(described_class).to have_received(:execute_script).with(script_name, redis, keys, argv).twice
        end
      end
    end
  end
end
