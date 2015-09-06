require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'
require 'sidekiq_unique_jobs/client/middleware'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

RSpec.describe 'Sidekiq::Api' do
  class JustAWorker
    include Sidekiq::Worker

    sidekiq_options unique: true, queue: 'testqueue'

    def perform
    end
  end

  before do
    Sidekiq.redis = REDIS
    Sidekiq.redis(&:flushdb)
  end

  let(:params) { { foo: 'bar' } }
  let(:payload_hash) { SidekiqUniqueJobs.get_payload('JustAWorker', 'testqueue', [params]) }

  def schedule_job
    JustAWorker.perform_in(60 * 60 * 3, params)
  end

  def perform_async
    JustAWorker.perform_async(foo: 'bar')
  end

  describe Sidekiq::SortedEntry::UniqueExtension, sidekiq_ver: '>= 3.1' do
    it 'deletes uniqueness lock on delete' do
      schedule_job

      Sidekiq::ScheduledSet.new.each(&:delete)
      Sidekiq.redis do |c|
        expect(c.exists(payload_hash)).to be_falsy
      end

      expect(schedule_job).not_to eq(nil)
    end
  end

  describe Sidekiq::Job::UniqueExtension do
    it 'deletes uniqueness lock on delete' do
      jid = perform_async
      Sidekiq::Queue.new('testqueue').find_job(jid).delete
      Sidekiq.redis do |c|
        expect(c.exists(payload_hash)).to be_falsy
      end
    end
  end

  describe Sidekiq::Queue::UniqueExtension do
    it 'deletes uniqueness locks on clear' do
      perform_async
      Sidekiq::Queue.new('testqueue').clear
      Sidekiq.redis do |c|
        expect(c.exists(payload_hash)).to be_falsy
      end
    end
  end

  describe Sidekiq::JobSet::UniqueExtension, sidekiq_ver: '>= 3' do
    it 'deletes uniqueness locks on clear' do
      schedule_job
      Sidekiq::JobSet.new('schedule').clear
      Sidekiq.redis do |c|
        expect(c.exists(payload_hash)).to be_falsy
      end
    end
  end
end
