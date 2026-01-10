# frozen_string_literal: true

RSpec.shared_examples "an executing lock implementation" do
  context "when job can't be locked" do
    before do
      allow(process_one.locksmith).to receive(:execute).and_return(nil)
    end

    it "does not execute" do
      unset = true
      process_one.execute { unset = false }
      expect(unset).to be(true)
    end
  end

  context "when process_one executes the job" do
    before { process_one.lock }

    it "keeps being locked while executing" do
      process_one.execute do
        expect(process_one).to be_locked
      end
    end

    it "keeps being locked when an error is raised" do
      allow(process_one.locksmith).to receive(:execute).and_raise(RuntimeError, "Hell")

      expect { process_one.execute { "hey ho" } }.to raise_error("Hell")

      expect(process_one).to be_locked
    end

    it "prevents process_two from locking" do
      process_one.execute do
        expect(process_two.lock).to be_nil
        expect(process_two).not_to be_locked
      end
    end

    it "prevents process_two from executing" do
      expect { process_two.execute { raise "Hell" } }.not_to raise_error
    end

    it "reflects execution_failed on failure" do
      allow(process_two).to receive(:reflect).and_call_original
      process_two.execute {}

      expect(process_two).to have_received(:reflect).with(:execution_failed, item_two)
    end

    it "yields without arguments" do
      process_one.lock
      process_one.execute {}
      blk = -> {}

      expect { process_one.execute(&blk) }.not_to raise_error
    end
  end
end
