# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuting do
  let(:process_one) { described_class.new(item_one, callback) }
  let(:process_two) { described_class.new(item_two, callback) }

  let(:jid_one)   { "jid one" }
  let(:jid_two)   { "jid two" }
  let(:job_class) { UntilExecutingJob }
  let(:unique)    { :until_executing }
  let(:queue)     { :executed }
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
    it "unlocks before executing" do
      process_one.lock
      process_one.execute do
        expect(process_one).not_to be_locked
      end
    end

    context "when error is raised" do
      let(:block) { -> { raise "Hell" } }

      it "locks the job again" do
        process_one.lock
        process_one.execute(&block)
        expect(process_one).to be_locked
      end

      it "reflects execution failed" do
        allow(process_one).to receive(:reflect)

        process_one.lock
        process_one.execute(&block)

        expect(process_one).to have_received(:reflect)
          .with(:execution_failed, item_one, kind_of(RuntimeError))
      end
    end
  end
end
