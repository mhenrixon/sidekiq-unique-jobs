# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq_unique_jobs/web'
require 'rack/test'

RSpec.describe SidekiqUniqueJobs::Web do
  include Rack::Test::Methods

  def app
    Sidekiq::Web
  end

  before do
    Sidekiq.redis(&:flushdb)
  end

  let(:digest) { SidekiqUniqueJobs::Digests.all(count: 1).first }

  it 'can display keys' do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)

    get '/unique_digests'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to match('/unique_digests/uniquejobs:9e9b5ce5d423d3ea470977004b50ff84')
  end

  xit 'can display key' do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)

    get "/unique_digests/#{digest}"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to match('/unique_digests/uniquejobs:9e9b5ce5d423d3ea470977004b50ff84')
  end

  xit 'can delete a queue' do
    Sidekiq.redis do |conn|
      conn.rpush('queue:foo', '{\"args\":[]}')
      conn.sadd('queues', 'foo')
    end

    get '/queues/foo'
    assert_equal 200, last_response.status

    post '/queues/foo'
    assert_equal 302, last_response.status

    Sidekiq.redis do |conn|
      refute conn.smembers('queues').include?('foo')
      refute conn.exists('queue:foo')
    end
  end

  xit 'can delete a job' do
    Sidekiq.redis do |conn|
      conn.rpush('queue:foo', '{"args":[]}')
      conn.rpush('queue:foo', '{"foo":"bar","args":[]}')
      conn.rpush('queue:foo', '{"foo2":"bar2","args":[]}')
    end

    get '/queues/foo'
    assert_equal 200, last_response.status

    post '/queues/foo/delete', key_val: '{"foo":"bar"}'
    assert_equal 302, last_response.status

    Sidekiq.redis do |conn|
      refute conn.lrange('queue:foo', 0, -1).include?('{"foo":"bar"}')
    end
  end

  xdescribe 'custom locales' do
    before do
      Sidekiq::Web.settings.locales << File.join(File.dirname(__FILE__), 'fixtures')
      Sidekiq::Web.tabs['Custom Tab'] = '/custom'
      Sidekiq::WebApplication.get('/custom') do
        clear_caches # ugly hack since I can't figure out how to access WebHelpers outside of this context
        t('translated_text')
      end
    end

    after do
      Sidekiq::Web.tabs.delete 'Custom Tab'
      Sidekiq::Web.settings.locales.pop
    end

    it 'can show user defined tab with custom locales' do
      get '/custom'

      assert_match(/Changed text/, last_response.body)
    end
  end

  def add_scheduled
    score = Time.now.to_f
    msg = { 'class' => 'HardWorker',
            'args' => ['bob', 1, Time.now.to_f],
            'jid' => SecureRandom.hex(12) }
    Sidekiq.redis do |conn|
      conn.zadd('schedule', score, Sidekiq.dump_json(msg))
    end
    [msg, score]
  end

  def add_retry
    msg = { 'class' => 'HardWorker',
            'args' => ['bob', 1, Time.now.to_f],
            'queue' => 'default',
            'error_message' => 'Some fake message',
            'error_class' => 'RuntimeError',
            'retry_count' => 0,
            'failed_at' => Time.now.to_f,
            'jid' => SecureRandom.hex(12) }
    score = Time.now.to_f
    Sidekiq.redis do |conn|
      conn.zadd('retry', score, Sidekiq.dump_json(msg))
    end

    [msg, score]
  end

  def add_dead
    msg = { 'class' => 'HardWorker',
            'args' => ['bob', 1, Time.now.to_f],
            'queue' => 'foo',
            'error_message' => 'Some fake message',
            'error_class' => 'RuntimeError',
            'retry_count' => 0,
            'failed_at' => Time.now.utc,
            'jid' => SecureRandom.hex(12) }
    score = Time.now.to_f
    Sidekiq.redis do |conn|
      conn.zadd('dead', score, Sidekiq.dump_json(msg))
    end
    [msg, score]
  end

  def kill_bad
    job = '{ something bad }'
    score = Time.now.to_f
    Sidekiq.redis do |conn|
      conn.zadd('dead', score, job)
    end
    [job, score]
  end

  def add_xss_retry(_job_id = SecureRandom.hex(12))
    msg = { 'class' => 'FailWorker',
            'args' => ['<a>hello</a>'],
            'queue' => 'foo',
            'error_message' => 'fail message: <a>hello</a>',
            'error_class' => 'RuntimeError',
            'retry_count' => 0,
            'failed_at' => Time.now.to_f,
            'jid' => SecureRandom.hex(12) }
    score = Time.now.to_f
    Sidekiq.redis do |conn|
      conn.zadd('retry', score, Sidekiq.dump_json(msg))
    end

    [msg, score]
  end

  def add_worker
    key = "#{hostname}:#{$PROCESS_ID}"
    msg = '{"queue":"default","payload":{"retry":true,"queue":"default","timeout":20,"backtrace":5,"class":"HardWorker","args":["bob",10,5],"jid":"2b5ad2b016f5e063a1c62872"},"run_at":1361208995}'
    Sidekiq.redis do |conn|
      conn.multi do
        conn.sadd('processes', key)
        conn.hmset(key, 'info', Sidekiq.dump_json('hostname' => 'foo', 'started_at' => Time.now.to_f, 'queues' => []), 'at', Time.now.to_f, 'busy', 4)
        conn.hmset("#{key}:workers", Time.now.to_f, msg)
      end
    end
  end
end
