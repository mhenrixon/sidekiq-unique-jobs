# frozen_string_literal: true

require "sidekiq/fetch"

RSpec.describe SidekiqUniqueJobs::Fetch::LockAware do
  let(:fetch) { described_class.new(capsule) }
  let(:capsule) do
    instance_double(Sidekiq::Capsule, config: capsule_config).tap do |cap|
      allow(cap).to receive_messages(queues: ["default"], mode: :strict, weights: {})
    end
  end
  let(:capsule_config) { { inner_fetch_class: nil } }

  let(:inner_fetch) { instance_double(Sidekiq::BasicFetch) }

  before do
    allow(Sidekiq::BasicFetch).to receive(:new).and_return(inner_fetch)
  end

  describe "#initialize" do
    it "creates an inner BasicFetch by default" do
      described_class.new(capsule)

      expect(Sidekiq::BasicFetch).to have_received(:new).with(capsule)
    end

    context "when inner_fetch_class is configured" do
      let(:custom_fetch) { Class.new { def initialize(_capsule); end } }
      let(:capsule_config) { { inner_fetch_class: custom_fetch } }

      it "uses the configured fetch class" do
        lock_aware = described_class.new(capsule)
        inner = lock_aware.instance_variable_get(:@inner_fetch)

        expect(inner).to be_a(custom_fetch)
      end
    end
  end

  describe "#retrieve_work" do
    context "when inner fetch returns nil" do
      before { allow(inner_fetch).to receive(:retrieve_work).and_return(nil) }

      it "returns nil" do
        expect(fetch.retrieve_work).to be_nil
      end
    end

    context "when inner fetch returns work" do
      let(:inner_work) do
        instance_double(Sidekiq::BasicFetch::UnitOfWork,
          queue: "queue:default",
          job: dump_json(job_hash),
          config: nil,
          queue_name: "default")
      end

      let(:job_hash) do
        {
          "class" => "MyUniqueJob",
          "jid" => "test-jid",
          "args" => [1],
          "lock_digest" => "uniquejobs:test",
        }
      end

      before { allow(inner_fetch).to receive(:retrieve_work).and_return(inner_work) }

      it "returns a LockAwareUnitOfWork" do
        result = fetch.retrieve_work

        expect(result).to be_a(SidekiqUniqueJobs::Fetch::LockAwareUnitOfWork)
      end

      it "wraps the inner work" do
        result = fetch.retrieve_work

        expect(result.inner_work).to eq(inner_work)
      end
    end

    context "when inner fetch returns a non-unique job" do
      let(:inner_work) do
        instance_double(Sidekiq::BasicFetch::UnitOfWork,
          queue: "queue:default",
          job: dump_json({ "class" => "RegularJob", "jid" => "abc", "args" => [] }),
          config: nil,
          queue_name: "default")
      end

      before { allow(inner_fetch).to receive(:retrieve_work).and_return(inner_work) }

      it "still wraps it" do
        result = fetch.retrieve_work

        expect(result).to be_a(SidekiqUniqueJobs::Fetch::LockAwareUnitOfWork)
      end
    end
  end

  describe "#bulk_requeue" do
    let(:first_inner_work) { double("first_uow", job: "{}") } # rubocop:disable RSpec/VerifiedDoubles
    let(:second_inner_work) { double("second_uow", job: "{}") } # rubocop:disable RSpec/VerifiedDoubles
    let(:first_wrapped) { SidekiqUniqueJobs::Fetch::LockAwareUnitOfWork.new(first_inner_work) }
    let(:second_wrapped) { SidekiqUniqueJobs::Fetch::LockAwareUnitOfWork.new(second_inner_work) }

    before do
      allow(inner_fetch).to receive(:bulk_requeue)
    end

    it "unwraps and delegates to inner fetch" do
      fetch.bulk_requeue([first_wrapped, second_wrapped])

      expect(inner_fetch).to have_received(:bulk_requeue)
        .with([first_inner_work, second_inner_work])
    end
  end
end
