# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockDigest do
  let(:digest)       { described_class.new(item) }
  let(:worker_class) { UntilExecutedJob }
  let(:class_name)   { worker_class.to_s }
  let(:queue)        { "myqueue" }
  let(:args)         { [[1, 2]] }
  let(:item)         { base_item }
  let(:base_item) do
    {
      "class" => class_name,
      "queue" => queue,
      "lock_args" => args,
    }
  end

  describe "#lock_digest" do
    subject(:lock_digest) { digest.lock_digest }

    context "when args are empty" do
      let(:digest_two)   { described_class.new(item) }
      let(:worker_class) { WithoutArgumentJob }
      let(:args)         { [] }

      context "with the same unique args" do
        it "equals to lock_digest for that item" do
          expect(lock_digest).to eq(digest_two.lock_digest)
        end
      end
    end

    shared_examples "unique digest" do
      context "with another item" do
        let(:digest_two) { described_class.new(another_item) }

        context "with the same unique args" do
          let(:another_item) { item }

          it "equals to lock_digest for that item" do
            expect(lock_digest).to eq(digest_two.lock_digest)
          end
        end

        context "with different unique args" do
          let(:another_item) { item.merge("lock_args" => [1, 3, { "type" => "that" }]) }

          it "differs from lock_digest for that item" do
            expect(lock_digest).not_to eq(digest_two.lock_digest)
          end
        end
      end
    end

    context "when digest is a proc" do
      let(:worker_class) { MyUniqueJobWithFilterProc }
      let(:args)         { [1, 2, { "type" => "it" }] }

      it_behaves_like "unique digest"
    end

    context "when unique_args is a symbol" do
      let(:worker_class) { MyUniqueJobWithFilterMethod }
      let(:args)         { [1, 2, { "type" => "it" }] }

      it_behaves_like "unique digest"
    end
  end

  describe "#digestable_hash" do
    subject(:digestable_hash) { digest.digestable_hash }

    it { is_expected.to eq("class" => "UntilExecutedJob", "queue" => "myqueue", "lock_args" => [[1, 2]]) }

    context "when used with apartment gem" do
      let(:item) { base_item.merge("apartment" => "public") }

      it "appends apartment to digestable hash" do
        expect(digestable_hash).to eq(
          "class" => "UntilExecutedJob",
          "queue" => "myqueue",
          "lock_args" => [[1, 2]],
          "apartment" => "public",
        )
      end
    end

    context "when unique_across_queues", :with_worker_options do
      let(:worker_options) { { unique_across_queues: true } }

      it { is_expected.to eq("class" => "UntilExecutedJob", "lock_args" => [[1, 2]]) }
    end

    context "when unique_across_workers", :with_worker_options do
      let(:worker_options) { { unique_across_workers: true } }

      it { is_expected.to eq("queue" => "myqueue", "lock_args" => [[1, 2]]) }
    end
  end

  describe "#unique_across_queues?" do
    subject(:unique_across_queues?) { digest.unique_across_queues? }

    it { is_expected.to eq(nil) }

    context "when unique_across_queues: true", :with_worker_options do
      let(:worker_options) { { unique_across_queues: true } }

      it { is_expected.to eq(true) }
    end

    context "when unique_across_queues: false", :with_worker_options do
      let(:worker_options) { { unique_across_queues: false } }

      it { is_expected.to eq(false) }
    end
  end

  describe "#unique_across_workers?" do
    subject(:unique_across_workers?) { digest.unique_across_workers? }

    it { is_expected.to eq(nil) }

    context "when unique_across_workers: true", :with_worker_options do
      let(:worker_options) { { unique_across_workers: true } }

      it { is_expected.to eq(true) }
    end

    context "when unique_across_workers: false", :with_worker_options do
      let(:worker_options) { { unique_across_workers: false } }

      it { is_expected.to eq(false) }
    end
  end
end
