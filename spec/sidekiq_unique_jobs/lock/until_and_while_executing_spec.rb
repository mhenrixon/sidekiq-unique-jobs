# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting, redis_db: 3 do
  let(:process_one)  { described_class.new(item_one, callback) }
  let(:unique)       { :until_and_while_executing }
  let(:queue)        { :another_queue }
  let(:args)         { [sleepy_time] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { "jid" => jid_one,
      "class" => worker_class.to_s,
      "queue" => queue,
      "lock" => unique,
      "args" => args,
      "lock_timeout" => lock_timeout }
  end
  let(:item_two) do
    item_one.merge("jid" => jid_two)
  end
  let(:runtime_one) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item_one.dup, callback) }

  let(:process_two) { described_class.new(item_two, callback) }
  let(:runtime_two) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item_two.dup, callback) }

  let(:jid_one)      { "jid one" }
  let(:jid_two)      { "jid two" }
  let(:lock_timeout) { nil }
  let(:sleepy_time)  { 0 }

  if Sidekiq.const_defined?("JobRecord")
    let(:worker_class) { AnotherUniqueJobJob }
  else
    let(:worker_class) { UntilAndWhileExecutingJob }
  end

  before do
    allow(process_one).to receive(:runtime_lock).and_return(runtime_one)
    allow(process_two).to receive(:runtime_lock).and_return(runtime_two)
  end

  it_behaves_like "a lock implementation"

  it "has not locked runtime_one" do
    process_one.lock
    expect(runtime_one).not_to be_locked
  end

  context "when process_one executes the job" do
    it "releases the lock for process_one" do
      process_one.execute do
        expect(process_one).not_to be_locked
      end
    end

    it "is locked by runtime_one" do
      process_one.execute do
        expect(runtime_one).to be_locked
      end
    end

    it "allows process_two to lock" do
      process_one.execute do
        expect(process_two.lock).to eq(jid_two)
      end
    end

    it "prevents process_two from executing" do
      process_one.lock
      expect { process_two.execute { raise "Hell" } }.not_to raise_error
    end

    it "process two cannot execute the job" do
      process_one.execute do
        process_two.lock
        unset = true
        process_two.execute { unset = false }
        expect(unset).to eq(true)
      end
    end

    context "when worker raises error in runtime lock" do
      before do
        allow(runtime_one.locksmith).to receive(:lock).and_raise(RuntimeError, "Hell")
      end

      it "always unlocks" do
        process_one.lock

        expect { process_one.execute {} }
          .to raise_error(RuntimeError, "Hell")

        expect(runtime_one.locked?).to eq(false)
        expect(process_one.locked?).to eq(true)
      end
    end
  end
end
