require 'spec_helper'

begin
  require 'mock_redis'
  MOCK_REDIS ||= MockRedis.new
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # This is a known issue (we only run this spec for ruby 2.4.1)
end

RSpec.describe SidekiqUniqueJobs::ScriptMock, ruby_ver: '>= 2.4.1' do
  MD5_DIGEST ||= 'unique'.freeze
  UNIQUE_KEY ||= 'uniquejobs:unique'.freeze
  JID ||= 'fuckit'.freeze
  ANOTHER_JID ||= 'anotherjid'.freeze

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

  subject { SidekiqUniqueJobs::Scripts }

  def lock_for(seconds = 1, jid = JID, key = UNIQUE_KEY)
    subject.call(:acquire_lock, nil, keys: [key], argv: [jid, seconds])
  end

  def unlock(key = UNIQUE_KEY, jid = JID)
    subject.call(:release_lock, nil, keys: [key], argv: [jid])
  end

  describe '.acquire_lock' do
    context 'when job is unique' do
      specify { expect(lock_for).to eq(1) }
      specify do
        expect(lock_for(1)).to eq(1)
        expect(SidekiqUniqueJobs)
          .to have_key(UNIQUE_KEY)
          .for_seconds(1)
          .with_value('fuckit')
        sleep 1
        expect(lock_for).to eq(1)
      end

      context 'when job is locked' do
        before  { expect(lock_for(10)).to eq(1) }
        specify { expect(lock_for(5, ANOTHER_JID)).to eq(0) }
      end
    end

    describe '.release_lock' do
      context 'when job is locked by another jid' do
        before  { expect(lock_for(10, ANOTHER_JID)).to eq(1) }
        specify { expect(unlock).to eq(0) }
        after { unlock(UNIQUE_KEY, ANOTHER_JID) }
      end

      context 'when job is not locked at all' do
        specify { expect(unlock).to eq(-1) }
      end

      context 'when job is locked by the same jid' do
        specify do
          expect(lock_for(10)).to eq(1)
          expect(unlock).to eq(1)
        end
      end
    end
  end
end
