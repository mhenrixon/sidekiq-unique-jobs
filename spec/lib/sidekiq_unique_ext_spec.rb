require 'spec_helper'
require 'sidekiq/api'
require 'sidekiq/worker'
require 'sidekiq_unique_jobs/server/middleware'
require 'sidekiq_unique_jobs/server/mock_lib'
require 'sidekiq_unique_jobs/client/middleware'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

class JustAWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, queue: 'testqueue'

  def perform
  end
end

# rubocop:disable ClassAndModuleChildren
class Sidekiq::Job
  def _sidekiq_redis
    Sidekiq.redis do |con|
      yield con
    end
  end
  include SidekiqUniqueJobs::Server::MockLib
  alias_method :connection, :_sidekiq_redis
end
# rubocop:enable ClassAndModuleChildren

describe Sidekiq::Job::UniqueExtension do
  before do
    Sidekiq.redis = REDIS
    Sidekiq.redis(&:flushdb)
  end

  it 'deletes uniqueness lock on delete' do
    params = { foo: 'bar' }
    payload_hash = SidekiqUniqueJobs.get_payload('JustAWorker', 'testqueue', [params])
    jid = JustAWorker.perform_async(foo: 'bar')
    queue = Sidekiq::Queue.new('testqueue')
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
    Sidekiq.redis(&:flushdb)
  end

  it 'deletes uniqueness locks on clear' do
    params = { foo: 'bar' }
    payload_hash = SidekiqUniqueJobs.get_payload('JustAWorker', 'testqueue', [params])
    JustAWorker.perform_async(foo: 'bar')
    queue = Sidekiq::Queue.new('testqueue')
    queue.clear
    Sidekiq.redis do |c|
      expect(c.exists(payload_hash)).to be_falsy
    end
  end
end

describe Sidekiq::JobSet::UniqueExtension, sidekiq_ver: 3 do
  before do
    Sidekiq.redis = REDIS
    Sidekiq.redis(&:flushdb)
  end

  it 'deletes uniqueness locks on clear' do
    params = { foo: 'bar' }
    payload_hash = SidekiqUniqueJobs.get_payload('JustAWorker', 'testqueue', [params])
    JustAWorker.perform_in(60 * 60 * 3, foo: 'bar')
    set = Sidekiq::JobSet.new('schedule')
    set.clear
    Sidekiq.redis do |c|
      expect(c.exists(payload_hash)).to be_falsy
    end
  end
end
