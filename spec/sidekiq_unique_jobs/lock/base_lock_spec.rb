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

  describe "#callback_safely" do
    subject(:callback_safely) { lock.send(:callback_safely) }

    context "when callback raises an error" do
      let(:error) { RuntimeError.new("Hell") }

      before do
        allow(callback).to receive(:call).and_raise(error)
        allow(lock).to receive(:reflect)
        allow(lock).to receive(:log_warn)
      end

      it "reflects a warning and logs but does not re-raise" do
        expect { callback_safely }.not_to raise_error
        expect(lock).to have_received(:reflect).with(:after_unlock_callback_failed, item, error)
        expect(lock).to have_received(:log_warn).with("After unlock callback failed: RuntimeError - Hell")
        expect(callback_safely).to eq(item[SidekiqUniqueJobs::JID])
      end
    end
  end
end
