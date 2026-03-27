# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::UntilExpired do
  let(:process_one) { described_class.new(item_one, callback) }
  let(:process_two) { described_class.new(item_two, callback) }

  let(:jid_one)   { "jid one" }
  let(:jid_two)   { "jid two" }
  let(:job_class) { UntilExpiredJob }
  let(:unique)    { :until_expired }
  let(:queue)     { :rejecting }
  let(:args)      { %w[array of arguments] }
  let(:callback)  { -> {} }
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
    allow(callback).to receive(:call).and_call_original
  end

  describe "#lock" do
    it_behaves_like "a lock implementation"
  end

  describe "#execute" do
    it_behaves_like "an executing lock implementation"

    it "keeps lock after executing" do
      process_one.lock
      process_one.execute {}
      expect(process_one).to be_locked
    end

    context "when worker returns nil (early exit)" do
      it "does not reflect execution_failed" do
        allow(process_one).to receive(:reflect)

        process_one.lock
        process_one.execute { nil }

        expect(process_one).not_to have_received(:reflect)
          .with(:execution_failed, anything)
      end
    end

    context "when worker returns false" do
      it "does not reflect execution_failed" do
        allow(process_one).to receive(:reflect)

        process_one.lock
        process_one.execute { false }

        expect(process_one).not_to have_received(:reflect)
          .with(:execution_failed, anything)
      end
    end

    context "when lock cannot be acquired" do
      it "still reflects execution_failed" do
        allow(process_two).to receive(:reflect)

        process_one.lock
        process_two.execute { raise "should not run" }

        expect(process_two).to have_received(:reflect)
          .with(:execution_failed, item_two)
      end
    end
  end
end
