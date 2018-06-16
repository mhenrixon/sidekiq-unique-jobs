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

    it 'deletes uniqueness lock on remove_job' do
      expect(JustAWorker.perform_in(60 * 60 * 3, foo: 'bar')).to be_truthy
      Sidekiq.redis do |conn|
        expect(conn.keys).to include(
          'uniquejobs:863b7cb639bd71c828459b97788b2ada:EXISTS',
          'uniquejobs:863b7cb639bd71c828459b97788b2ada:GRABBED',
        )
      end

      Sidekiq::ScheduledSet.new.each do |entry|
        entry.send(:remove_job) do |message|
          item = Sidekiq.load_json(message)
          expect(item).to match(
            hash_including(
              'args' => [{ 'foo' => 'bar' }],
              'class' => 'JustAWorker',
              'jid' => kind_of(String),
              'lock_expiration' => nil,
              'lock_timeout' => 0,
              'queue' => 'testqueue',
              'retry' => true,
              'unique' => 'until_executed',
              'unique_args' => [{ 'foo' => 'bar' }],
              'unique_digest' => 'uniquejobs:863b7cb639bd71c828459b97788b2ada',
              'unique_prefix' => 'uniquejobs',
            ),
          )
        end
      end
      Sidekiq.redis do |conn|
        expect(conn.keys).to match_array([])
      end

      expect(JustAWorker.perform_in(60 * 60 * 3, boo: 'far')).to be_truthy
    end
  end

  describe Sidekiq::Job::UniqueExtension do
    it 'deletes uniqueness lock on delete' do
      jid = JustAWorker.perform_async(roo: 'baf')
      expect(SidekiqUniqueJobs::Util.keys).not_to match_array([])
      Sidekiq::Queue.new('testqueue').find_job(jid).delete
      expect(SidekiqUniqueJobs::Util.keys).to match_array([])
    end
  end

  describe Sidekiq::Queue::UniqueExtension do
    it 'deletes uniqueness locks on clear' do
      JustAWorker.perform_async(oob: 'far')
      expect(SidekiqUniqueJobs::Util.keys).not_to match_array([])
      Sidekiq::Queue.new('testqueue').clear
      expect(SidekiqUniqueJobs::Util.keys).to match_array([])
    end
  end

  describe Sidekiq::JobSet::UniqueExtension do
    it 'deletes uniqueness locks on clear' do
      JustAWorker.perform_in(60 * 60 * 3, roo: 'fab')
      expect(SidekiqUniqueJobs::Util.keys).not_to match_array([])
      Sidekiq::JobSet.new('schedule').clear
      expect(SidekiqUniqueJobs::Util.keys).to match_array([])
    end
  end
end
