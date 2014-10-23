require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs/middleware/server/unique_jobs'
require 'sidekiq-unique-jobs/middleware/client/unique_jobs'
require 'sidekiq_unique_ext'

class JustAWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, queue: 'testqueue'

  def perform
  end
end

describe Sidekiq::Job::UniqueExtension do


  before do
    Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  it 'deletes uniqueness lock on delete' do
    params = {:foo => "bar"}
    payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload("JustAWorker", "testqueue", [params])
    jid = JustAWorker.perform_async(:foo => "bar")
    queue = Sidekiq::Queue.new("testqueue")
    job = queue.find_job(jid)
    job.delete
    Sidekiq.redis do |c|
      expect(c.exists(payload_hash)).to be_falsy
    end
  end
end

describe Sidekiq::Queue::UniqueExtension do

  before do
    Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  it 'deletes uniqueness locks on clear' do
    params = {:foo => "bar"}
    payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload("JustAWorker", "testqueue", [params])
    JustAWorker.perform_async(:foo => "bar")
    queue = Sidekiq::Queue.new("testqueue")
    queue.clear
    Sidekiq.redis do |c|
      expect(c.exists(payload_hash)).to be_falsy
    end
  end
end
