# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting, redis: :redis do
  include SidekiqHelpers

  let(:process_one) { described_class.new(item_one, callback) }
  let(:process_two) { described_class.new(item_two, callback) }

  let(:jid_one)      { "jid one" }
  let(:jid_two)      { "jid two" }
  let(:worker_class) { WhileExecutingJob }
  let(:unique)       { :while_executing }
  let(:queue)        { :while_executing }
  let(:args)         { %w[array of arguments] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { "jid" => jid_one,
      "class" => worker_class.to_s,
      "queue" => queue,
      "lock" => unique,
      "args" => args }
  end
  let(:item_two) do
    { "jid" => jid_two,
      "class" => worker_class.to_s,
      "queue" => queue,
      "lock" => unique,
      "args" => args }
  end

  before do
    allow(callback).to receive(:call).and_call_original
  end

  describe "#lock" do
    it "does not lock jobs" do
      expect(process_one.lock).to eq(true)
      expect(process_one).not_to be_locked

      expect(process_two.lock).to eq(true)
      expect(process_two).not_to be_locked
    end
  end

  describe "#execute" do
    context "when executing" do
      it "locks the process" do
        process_one.execute do
          expect(process_one).to be_locked
        end
      end

      it "calls back" do
        process_one.execute {}
        expect(callback).to have_received(:call)
      end

      it "prevents other processes from executing" do
        process_one.execute do
          unset = true
          process_two.execute { unset = false }
          expect(unset).to eq(true)
        end

        expect(callback).to have_received(:call).once
      end
    end
  end
end
