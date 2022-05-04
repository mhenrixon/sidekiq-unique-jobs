# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting do
  let(:process_one) { described_class.new(item_one, callback_one) }
  let(:process_two) { described_class.new(item_two, callback_two) }

  let(:jid_one)      { "jid one" }
  let(:jid_two)      { "jid two" }
  let(:job_class)    { WhileExecutingJob }
  let(:unique)       { :while_executing }
  let(:queue)        { :while_executing }
  let(:args)         { %w[array of arguments] }
  let(:callback_one) { -> {} }
  let(:callback_two) { -> {} }
  let(:item_one) do
    { "jid" => jid_one,
      "class" => job_class.to_s,
      "queue" => queue,
      "lock" => unique,
      "args" => args }
  end
  let(:item_two) do
    { "jid" => jid_two,
      "class" => job_class.to_s,
      "queue" => queue,
      "lock" => unique,
      "args" => args }
  end

  before do
    allow(callback_one).to receive(:call).and_call_original if callback_one
    allow(callback_two).to receive(:call).and_call_original if callback_two
  end

  describe "#lock" do
    it "does not lock jobs" do
      expect(process_one.lock).to eq(jid_one)
      expect(process_one).not_to be_locked

      expect(process_two.lock).to eq(jid_two)
      expect(process_two).not_to be_locked
    end
  end

  describe "#execute" do
    it "locks the process" do
      process_one.execute do
        expect(process_one).to be_locked
      end
    end

    it "calls back" do
      process_one.execute {}
      expect(callback_one).to have_received(:call)
    end

    it "prevents other processes from executing" do
      flush_redis
      process_one.execute do
        unset = true
        process_two.execute { unset = false }
        expect(unset).to be(true)
      end

      expect(callback_one).to have_received(:call).once
      expect(callback_two).not_to have_received(:call)
    end

    it "yields without arguments" do
      process_one.lock
      process_one.execute {}
      blk = -> {}

      expect { process_one.execute(&blk) }.not_to raise_error
    end

    context "when no callback is defined" do
      let(:job_class) { WhileExecutingRescheduleJob }
      let(:callback_one) { -> { true } }
      let(:callback_two) { nil }

      let(:strategy_one) { process_one.send(:server_strategy) }
      let(:strategy_two) { process_two.send(:server_strategy) }

      before do
        allow(strategy_one).to receive(:call).and_call_original
        allow(strategy_two).to receive(:call).and_call_original
        allow(process_two).to receive(:reflect).and_call_original
      end

      it "reflects execution_failed" do
        process_one.execute do
          process_two.execute { puts "BOGUS!" }
        end

        expect(callback_one).to have_received(:call).once
        expect(strategy_one).not_to have_received(:call)
        expect(strategy_two).to have_received(:call).once

        expect(process_two).to have_received(:reflect).with(:execution_failed, item_two)
      end
    end

    context "when worker raises error" do
      before do
        allow(process_one.locksmith).to receive(:execute).and_raise(RuntimeError, "Hell")
      end

      it "always unlocks" do
        expect { process_one.execute { raise "Hell" } }
          .to raise_error(RuntimeError, "Hell")

        expect(process_one).not_to be_locked
      end
    end
  end
end
