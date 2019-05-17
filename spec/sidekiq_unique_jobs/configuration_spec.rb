# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs do
  describe "define custom lock strategies" do
    class FoobarJob < MyJob
      sidekiq_options lock: :foobar,
                      queue: :customqueue,
                      on_conflict: :raise
    end

    class CustomLock < SidekiqUniqueJobs::Lock::BaseLock
      def lock
        true
      end
    end

    subject(:middleware_call) do
      SidekiqUniqueJobs::Middleware::Client.new.call(worker_class, item, queue) do
        true
      end
    end

    let(:queue)     { :customqueue }
    let(:lock_type) { :foobar }
    let(:digest)    { "1234567890" }
    let(:jid)       { "randomjid" }
    let(:ttl)       { nil }
    let(:item) do
      {
        SidekiqUniqueJobs::UNIQUE_DIGEST => digest,
        SidekiqUniqueJobs::JID => jid,
        SidekiqUniqueJobs::LOCK_EXPIRATION => ttl,
        SidekiqUniqueJobs::LOCK => lock_type,
      }
    end
    let(:worker_class) { FoobarJob }

    context "when the lock is not defined" do
      it "raises SidekiqUniqueJobs::UnknownLock" do
        expect { middleware_call }.to raise_exception(
          SidekiqUniqueJobs::UnknownLock, /No implementation for `lock: :foobar`/
        )
      end
    end

    context "when the lock is defined" do
      let(:custom_config) do
        SidekiqUniqueJobs::Config.default.tap do |cfg|
          cfg.add_lock :foobar, CustomLock
        end
      end

      before do
        allow(described_class).to receive(:config).and_return(custom_config)
      end

      it "returns the block given" do
        expect(middleware_call).to be(true)
      end
    end
  end
end
