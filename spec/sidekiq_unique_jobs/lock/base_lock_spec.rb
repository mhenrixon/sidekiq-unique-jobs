# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::BaseLock do
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> { p "debug" } }
  let(:strategy) { :replace }
  let(:jid)      { "bogusjobid" }
  let(:item) do
    { "class" => "JustAWorker",
      "queue" => "testqueue",
      "on_conflict" => strategy,
      "jid" => jid,
      "args" => [{ foo: "bar" }] }
  end

  describe "#execute" do
    subject(:execute) { lock.execute {} }

    it "raises a helpful error" do
      expect { execute }.to raise_error(
        NotImplementedError,
        "#execute needs to be implemented in SidekiqUniqueJobs::Lock::BaseLock",
      )
    end
  end

  describe "#replace?" do
    subject(:replace?) { lock.send(:replace?) }

    context "when strategy is not :replace" do
      let(:strategy) { :log }

      it { is_expected.to eq(false) }
    end

    context "when attempt is less than 2" do
      it { is_expected.to eq(true) }
    end

    context "when attempt is equal to 2" do
      before { lock.instance_variable_set(:@attempt, 2) }

      it { is_expected.to eq(false) }
    end
  end

  describe "#unlock_with_callback" do
    subject(:unlock_with_callback) { lock.send(:unlock_with_callback) }

    context "when lock can't be unlocked" do
      before do
        allow(callback).to receive(:call)

        allow(lock).to receive(:unlock).and_return(false)
        allow(lock).to receive(:log_warn)
      end

      it "logs a warning" do
        expect(unlock_with_callback).not_to eq(jid)
        expect(callback).not_to have_received(:call)
        expect(lock).to have_received(:log_warn).with("Might need to be unlocked manually", item)
      end
    end
  end

  describe "#callback_safely" do
    subject(:callback_safely) { lock.send(:callback_safely) }

    context "when callback raises an error" do
      before do
        allow(callback).to receive(:call).and_raise("Hell")
        allow(lock).to receive(:log_warn)
      end

      it "logs a warning" do
        expect { callback_safely }.to raise_error(RuntimeError, "Hell")
        expect(lock).to have_received(:log_warn).with("Unlocked successfully but the #after_unlock callback failed!", item)
      end
    end
  end
end
