# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuting, redis: :redis do
  let(:process_one) { described_class.new(item_one, callback) }
  let(:process_two) { described_class.new(item_two, callback) }

  let(:jid_one)      { "jid one" }
  let(:jid_two)      { "jid two" }
  let(:worker_class) { UntilExecutingJob }
  let(:unique)       { :until_executing }
  let(:queue)        { :executed }
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
  end

  describe "#delete" do
    subject(:delete) { process_one.delete }

    context "when locked" do
      context "when expiration is not negative" do
        it "deletes the lock without fuss" do
          worker_class.use_options(lock_expiration: nil) do
            process_one.lock
            expect { delete }.to change { unique_keys.size }.from(2).to(0)
          end
        end
      end

      context "when expiration is positive" do
        it "does not delete the lock" do
          worker_class.use_options(lock_expiration: 100) do
            process_one.lock
            expect { delete }.not_to change { unique_keys.size }
          end
        end
      end
    end
  end

  describe "#delete!" do
    subject(:delete!) { process_one.delete! }

    context "when locked" do
      before { process_one.lock }

      it "deletes the lock without fuss" do
        expect { delete! }.to change { unique_keys.size }.from(2).to(0)
      end
    end
  end
end
