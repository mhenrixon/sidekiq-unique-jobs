# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecutingReject do
  let(:process_one) { described_class.new(item_one, callback) }
  let(:process_two) { described_class.new(item_two, callback) }

  let(:jid_one)      { "jid one" }
  let(:jid_two)      { "jid two" }
  let(:worker_class) { WhileExecutingRejectJob }
  let(:unique)       { :while_executing_reject }
  let(:queue)        { :rejecting }
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

    shared_examples "rejects job to deadset" do
      it "moves subsequent jobs to dead queue" do
        process_one.execute do
          expect(dead_count).to eq(0)
          expect { process_two.execute {} }
            .to change { dead_count }.from(0).to(1)
        end
      end
    end

    it_behaves_like "rejects job to deadset"

    context "when Sidekiq::DeadSet respond to kill" do
      it_behaves_like "rejects job to deadset"
    end

    context "when Sidekiq::DeadSet does not respond to kill" do
      let(:strategy) { SidekiqUniqueJobs::OnConflict::Reject.new(item_two) }

      before do
        allow(strategy).to receive(:deadset_kill?).and_return(false)
        allow(process_two).to receive(:server_strategy).and_return(strategy)
      end

      it_behaves_like "rejects job to deadset"
    end
  end

  context "when worker raises error" do
    before do
      allow(process_one.locksmith).to receive(:execute).and_raise("Hell")
    end

    it "always unlocks" do
      expect { process_one.execute {} }
        .to raise_error(RuntimeError, "Hell")

      expect(process_one.locked?).to be(false)
    end
  end
end
