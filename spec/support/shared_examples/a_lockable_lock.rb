# frozen_string_literal: true

RSpec.shared_examples "a lock implementation" do
  before do
    allow(process_one).to receive(:reflect).and_call_original
    allow(process_two).to receive(:reflect).and_call_original
    allow(process_one).to receive(:call_strategy).and_call_original
    allow(process_two).to receive(:call_strategy).and_call_original
  end

  it "can be locked" do
    expect(process_one.lock).to eq(jid_one)
  end

  context "when process one has locked the job" do
    before { process_one.lock }

    it "has locked process_one" do
      expect(process_one).to be_locked
    end

    it "prevents process_two from locking" do
      expect(process_two.lock).to be_nil
    end

    it "prevents process_two from executing" do
      expect(process_two.execute {}).to be_nil
    end

    it "handles lock failures" do
      process_two.lock

      expect(process_two).to have_received(:reflect).with(:lock_failed, item_two)
      expect(process_two).to have_received(:call_strategy).with(origin: :client)
    end
  end
end
