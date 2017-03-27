require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'
require 'sidekiq_unique_jobs/client/middleware'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

RSpec.describe 'Sidekiq::Api' do
  before do
    Sidekiq.redis = REDIS
    Sidekiq.redis(&:flushdb)
  end

  let(:item) do
    { 'class' => JustAWorker,
      'queue' => 'testqueue',
      'args'  => [foo: 'bar'] }
  end

  def unique_key
    SidekiqUniqueJobs::UniqueArgs.digest(
      'class' => JustAWorker,
      'queue' => 'testqueue',
      'args'  => [foo: 'bar'],
      'at'    => (Date.today + 1).to_time.to_i
    )
  end

  def schedule_job
    JustAWorker.perform_in(60 * 60 * 3, foo: 'bar')
  end

  def perform_async
    JustAWorker.perform_async(foo: 'bar')
  end

  describe Sidekiq::SortedEntry::UniqueExtension do
    it 'deletes uniqueness lock on delete' do
      expect(schedule_job).to be_truthy

      Sidekiq::ScheduledSet.new.each(&:delete)
      Sidekiq.redis do |c|
        expect(c.exists(unique_key)).to be_falsy
      end

      expect(schedule_job).to be_truthy
    end
  end

  describe Sidekiq::Job::UniqueExtension do
    it 'deletes uniqueness lock on delete' do
      jid = perform_async
      Sidekiq::Queue.new('testqueue').find_job(jid).delete
      Sidekiq.redis do |c|
        expect(c.exists(unique_key)).to be_falsy
      end
      expect(true).to be_truthy
    end
  end

  describe Sidekiq::Queue::UniqueExtension do
    it 'deletes uniqueness locks on clear' do
      perform_async
      Sidekiq::Queue.new('testqueue').clear
      Sidekiq.redis do |c|
        expect(c.exists(unique_key)).to be_falsy
      end
    end
  end

  describe Sidekiq::JobSet::UniqueExtension do
    it 'deletes uniqueness locks on clear' do
      schedule_job
      Sidekiq::JobSet.new('schedule').clear
      Sidekiq.redis do |c|
        expect(c.exists(unique_key)).to be_falsy
      end
    end
  end
end
