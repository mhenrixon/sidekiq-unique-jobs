# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'
require 'sidekiq_unique_jobs/client/middleware'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

RSpec.describe 'Sidekiq::Api', redis: :redis do
  let(:item) do
    { 'class' => 'JustAWorker',
      'queue' => 'testqueue',
      'args'  => [foo: 'bar'] }
  end

  def unique_key
    SidekiqUniqueJobs::UniqueArgs.digest(
      'class' => 'JustAWorker',
      'queue' => 'testqueue',
      'args'  => [foo: 'bar'],
      'at'    => (Date.today + 1).to_time.to_i,
    )
  end

  describe Sidekiq::SortedEntry::UniqueExtension do
    it 'deletes uniqueness lock on delete' do
      expect(JustAWorker.perform_in(60 * 60 * 3, foo: 'bar')).to be_truthy
      Sidekiq.redis do |conn|
        expect(conn.keys).to include(
          'uniquejobs:863b7cb639bd71c828459b97788b2ada:EXISTS',
          'uniquejobs:863b7cb639bd71c828459b97788b2ada:GRABBED',
        )
      end

      Sidekiq::ScheduledSet.new.each(&:delete)
      Sidekiq.redis do |conn|
        expect(conn.keys).to match_array([])
      end

      expect(JustAWorker.perform_in(60 * 60 * 3, boo: 'far')).to be_truthy
    end
  end

  describe Sidekiq::Job::UniqueExtension do
    it 'deletes uniqueness lock on delete' do
      jid = JustAWorker.perform_async(roo: 'baf')
      Sidekiq::Queue.new('testqueue').find_job(jid).delete
      Sidekiq.redis do |conn|
        expect(conn.keys).to match_array(%w[queues])
      end
      expect(true).to be_truthy
    end
  end

  describe Sidekiq::Queue::UniqueExtension do
    it 'deletes uniqueness locks on clear' do
      JustAWorker.perform_async(oob: 'far')
      Sidekiq::Queue.new('testqueue').clear
      Sidekiq.redis do |conn|
        expect(conn.keys).to match_array([])
      end
    end
  end

  describe Sidekiq::JobSet::UniqueExtension do
    it 'deletes uniqueness locks on clear' do
      JustAWorker.perform_in(60 * 60 * 3, roo: 'fab')
      Sidekiq::JobSet.new('schedule').clear
      Sidekiq.redis do |conn|
        expect(conn.keys).to match_array([])
      end
    end
  end
end
