# frozen_string_literal: true

RSpec.shared_examples "a lock implementation" do
  it "can be locked" do
    expect(process_one.lock).to eq(jid_one)
  end

  context "when process one has locked the job" do
    before { process_one.lock }

    it "has locked process_one" do
      expect(process_one).to be_locked
    end

    it "prevents process_two from locking" do
      expect(process_two.lock).to eq(nil)
    end

    it "prevents process_two from executing" do
      expect(process_two.execute {}).to eq(nil)
    end
  end
end

RSpec.shared_examples "an executing lock implementation" do
  context "when job can't be locked" do
    before do
      allow(process_one.locksmith).to receive(:lock).and_return(nil)
    end
    it "does not execute" do
      unset = true
      process_one.execute { unset = false }
      expect(unset).to eq(true)
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
      allow(process_one.locksmith).to receive(:lock).and_raise(RuntimeError, "Hell")

      expect { process_one.execute {} }.to raise_error("Hell")

      expect(process_one).to be_locked
    end

    it "prevents process_two from locking" do
      process_one.execute do
        expect(process_two.lock).to eq(nil)
        expect(process_two).not_to be_locked
      end
    end

    it "prevents process_two from executing" do
      expect { process_two.execute { raise "Hell" } }.not_to raise_error
    end
  end
end
