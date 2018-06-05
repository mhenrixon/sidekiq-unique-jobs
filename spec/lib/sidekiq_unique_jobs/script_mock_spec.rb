# frozen_string_literal: true

require 'spec_helper'

begin
  require 'mock_redis'
  MOCK_REDIS ||= MockRedis.new
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # This is a known issue (we only run this spec for ruby 2.4.1)
end

RSpec.describe SidekiqUniqueJobs::ScriptMock, ruby_ver: '>= 2.5.1' do
  before do
    SidekiqUniqueJobs.configure do |config|
      config.redis_test_mode = :mock
    end
    Sidekiq::Worker.clear_all

    keys = MOCK_REDIS.keys
    if keys.respond_to?(:each)
      keys.each do |key|
        MOCK_REDIS.del(key)
      end
    else
      MOCK_REDIS.del(keys)
    end

    allow(Sidekiq).to receive(:redis).and_yield(MOCK_REDIS)
  end

  after do
    SidekiqUniqueJobs.configure do |config|
      config.redis_test_mode = :redis
    end
  end

  shared_context 'shared SciptMock setup' do
    let(:redis_pool)  { nil }
    let(:unique_key)  { 'uniquejobs:unique' }
    let(:jid)         { 'fuckit' }
    let(:another_jid) { 'anotherjid' }
    let(:seconds)     { 1 }
  end

  def acquire_lock(custom_jid = nil)
    described_class.acquire_lock(
      redis_pool,
      keys: [unique_key],
      argv: [custom_jid || jid, seconds],
    )
  end

  describe '.acquire_lock' do
    subject { acquire_lock }

    include_context 'shared SciptMock setup'

    context 'when job is unique' do
      it do
        expect(acquire_lock).to eq(1)
        expect(SidekiqUniqueJobs)
          .to have_key(unique_key)
          .for_seconds(1)
          .with_value('fuckit')
        sleep 1
        expect(acquire_lock).to eq(1)
      end
    end

    context 'when job is not unique' do
      let(:seconds) { 10 }
      before { expect(acquire_lock(another_jid)).to eq(1) }

      it { is_expected.to eq(0) }
    end
  end

  def release_lock(custom_jid = nil)
    described_class.release_lock(
      redis_pool,
      keys: [unique_key],
      argv: [custom_jid || jid, seconds],
    )
  end

  describe '.release_lock' do
    subject { release_lock }

    include_context 'shared SciptMock setup'

    context 'when job is locked by another jid' do
      before { expect(acquire_lock(another_jid)).to eq(1) }
      after { expect(release_lock(another_jid)).to eq(1) }

      it { is_expected.to eq(0) }
    end

    context 'when job is not locked at all' do
      specify { expect(release_lock).to eq(-1) }
    end

    context 'when job is locked by the same jid' do
      let(:seconds) { 10 }
      before { expect(acquire_lock).to eq(1) }

      it { is_expected.to eq(1) }
    end
  end
end
