require 'spec_helper'
require 'sidekiq/worker'
require "sidekiq-unique-jobs"
require 'sidekiq/scheduled'
require 'sidekiq-unique-jobs/middleware/server/unique_jobs'
require 'rspec-sidekiq'

describe "Sidekiq::Testing" do
  before { Sidekiq::Testing.fake! }
  before { SidekiqUniqueJobs.instance_variable_set(:@use_redis_mock, nil) }

  before {
    redis_mock.flushdb
    with_redis(&:flushdb)
  }

  def redis_mock
    SidekiqUniqueJobs.redis_mock
  end

  def with_redis
    Sidekiq.redis { |conn| yield(conn) }
  end

  describe '.testing_enabled?' do
    subject { SidekiqUniqueJobs.testing_enabled? }

    context 'When Sidekiq::Testing is enabled' do
      it { should be true }
    end

    context 'When Sidekiq::Testing has been disabled' do
      before { Sidekiq::Testing.disable! }
      it { should be false }
    end
  end  # .testing_enabled?

  describe 'Enabling/Disabling Mock Redis in Tests' do
    before { SidekiqUniqueJobs::Config.unique_args_enabled = true }
    after  { SidekiqUniqueJobs::Config.unique_args_enabled = false }

    let(:payload) { 'foobar' }
    let(:payload_hash) { SidekiqUniqueJobs::PayloadHelper.get_payload("UniqueWorker", "working", [payload]) }

    describe '.use_redis_mock?' do
      subject { SidekiqUniqueJobs.use_redis_mock? }

      context "it should default to true" do
        it { should be true }
      end
      context "it should be disable-able" do
        before { SidekiqUniqueJobs.disable_redis_mock! }
        it { should be false }
      end
    end # .use_redis_mock?

    describe 'When Mock Redis is Enabled' do
      it "should place a unique item in the Mock" do
        expect {
          UniqueWorker.perform_async(payload)
        }.to change { redis_mock.get(payload_hash) }.from(nil)

        with_redis { |conn| expect(conn.get(payload_hash)).to be nil }
      end

      it "should prevent duplicates" do
        expect {
          UniqueWorker.perform_async(payload)
        }.to change(UniqueWorker.jobs, :size).from(0).to(1)

        expect {
          UniqueWorker.perform_async(payload)
        }.not_to change(UniqueWorker.jobs, :size)
      end
    end

    describe 'When Mock Redis is Disabled' do
      before { SidekiqUniqueJobs.disable_redis_mock! }

      it "should place a unique item on Redis" do
        expect {
          UniqueWorker.perform_async(payload)
        }.to change {
          with_redis { |conn| conn.get(payload_hash) }
        }.from(nil)

        expect(redis_mock.get(payload_hash)).to be nil
      end

      it "should prevent duplicates" do
        expect {
          UniqueWorker.perform_async(payload)
        }.to change(UniqueWorker.jobs, :size).from(0).to(1)

        expect {
          UniqueWorker.perform_async(payload)
        }.not_to change(UniqueWorker.jobs, :size)
      end
    end
  end # describe 'Enabling/Disabling Mock Redis in Tests'

  describe "When Sidekiq::Testing is enabled" do
    describe 'After unique jobs have been performed' do
      before { SidekiqUniqueJobs::Config.unique_args_enabled = true }
      after  { SidekiqUniqueJobs::Config.unique_args_enabled = false }

      let(:payload) { 'foobar' }
      let(:payload_hash) { SidekiqUniqueJobs::PayloadHelper.get_payload("UniqueWorker", "working", [payload]) }

      # This test is failing
      it "should remove the unique lock for the job" do
        expect {
          UniqueWorker.perform_async(payload)
        }.to change { redis_mock.get(payload_hash) }.from(nil)

        Object.any_instance.stub(:puts) { }

        expect {
          UniqueWorker.drain
        }.to change { redis_mock.get(payload_hash) }.to(nil)
      end
    end # describe 'After unique jobs have been performed'

    describe 'when set to :fake!', sidekiq: :fake do
      context "with unique worker" do
        it "does not push duplicate messages" do
          param = 'work'
          expect(UniqueWorker.jobs.size).to eq(0)
          UniqueWorker.perform_async(param)
          expect(UniqueWorker.jobs.size).to eq(1)
          expect(UniqueWorker).to have_enqueued_job(param)
          UniqueWorker.perform_async(param)
          expect(UniqueWorker.jobs.size).to eq(1)
        end
      end

      context "with non-unique worker" do

        it "pushes duplicates messages" do
          param = 'work'
          expect(MyWorker.jobs.size).to eq(0)
          MyWorker.perform_async(param)
          expect(MyWorker.jobs.size).to eq(1)
          expect(MyWorker).to have_enqueued_job(param)
          MyWorker.perform_async(param)
          expect(MyWorker.jobs.size).to eq(2)
        end
      end
    end
  end # describe "When Sidekiq::Testing is enabled"
end
