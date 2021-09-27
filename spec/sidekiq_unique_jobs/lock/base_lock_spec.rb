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
    subject(:replace?) { lock.send(:replace?, origin) }

    let(:origin) { nil }

    shared_examples "valid replace?" do
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

    context "when origin is :client" do
      let(:origin) { :client }

      it_behaves_like "valid replace?"
    end

    context "when origin is :server" do
      let(:origin) { :server }

      it_behaves_like "valid replace?"
    end
  end

  describe "#callback_safely" do
    subject(:callback_safely) { lock.send(:callback_safely) }

    context "when callback raises an error" do
      before do
        allow(callback).to receive(:call).and_raise("Hell")
        allow(lock).to receive(:reflect)
      end

      it "reflects" do
      end

      it "logs a warning" do
        expect { callback_safely }.to raise_error(RuntimeError, "Hell")
        expect(lock).to have_received(:reflect).with(:after_unlock_callback_failed, item)
      end
    end
  end
end
