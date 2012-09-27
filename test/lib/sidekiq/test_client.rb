require 'helper'
require 'sidekiq/worker'
require "sidekiq-unique-jobs"
require 'sidekiq/scheduled'
require 'sidekiq-unique-jobs/middleware/server/unique_jobs'

class TestClient < MiniTest::Unit::TestCase
  describe 'with real redis' do
    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis {|c| c.flushdb }
      QueueWorker.sidekiq_options :unique => nil, :unique_job_expiration => nil
    end

    class QueueWorker
      include Sidekiq::Worker
      sidekiq_options :queue => 'customqueue'
      def perform(x)
      end
    end

    # This spec sometimes fails (unless it's the only spec that runs)
    # Not sure why, we tried a wide variety of ways to make sure that
    # there aren't side effects between tests and it still happens
    it 'is able to enqueue after the server middleware completes' do
      QueueWorker.sidekiq_options :unique => true
      request_item = {'class' => TestClient::QueueWorker, 'queue' => 'customqueue', 'args' => ["some arg"]}

      Sidekiq::Client.push(request_item.dup)
      assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }

      # Simulate sidekiq processing the job
      Sidekiq.redis {|c| c.lpop("queue:customqueue")}
      assert_equal 0, Sidekiq.redis {|c| c.llen("queue:customqueue") }

      SidekiqUniqueJobs::Middleware::Server::UniqueJobs.new.call("dummy arg", request_item.dup) {}

      Sidekiq::Client.push(request_item.dup) 
      assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    it 'does not push duplicate messages when configured for unique only' do
      QueueWorker.sidekiq_options :unique => true
      10.times { Sidekiq::Client.push('class' => TestClient::QueueWorker, 'queue' => 'customqueue',  'args' => [1, 2]) }
      assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    it 'sets an expiration when provided by sidekiq options' do
      one_hour_expiration = 60 * 60
      QueueWorker.sidekiq_options :unique => true, :unique_job_expiration => one_hour_expiration
      Sidekiq::Client.push('class' => TestClient::QueueWorker, 'queue' => 'customqueue',  'args' => [1, 2])

      md5_arguments = {:class => "TestClient::QueueWorker", :queue => "customqueue", :args => [1, 2]}
      payload_hash = Digest::MD5.hexdigest(Sidekiq.dump_json(md5_arguments))
      actual_expires_at = Sidekiq.redis {|c| c.ttl(payload_hash) }

      assert_in_delta one_hour_expiration, actual_expires_at, 2
    end

    it 'does push duplicate messages when not configured for unique only' do
      QueueWorker.sidekiq_options :unique => false
      10.times { Sidekiq::Client.push('class' => TestClient::QueueWorker, 'queue' => 'customqueue',  'args' => [1, 2]) }
      assert_equal 10, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    # TODO: If anyone know of a better way to check that the expiration for scheduled
    # jobs are set around the same time as the scheduled job itself feel free to improve.
    it 'expires the payload_hash when a scheduled job is scheduled at' do
      require 'active_support/all'
      QueueWorker.sidekiq_options :unique => true

      at = 15.minutes.from_now
      expected_expires_at = (Time.at(at) - Time.now.utc) + SidekiqUniqueJobs::Middleware::Client::UniqueJobs::HASH_KEY_EXPIRATION

      QueueWorker.perform_in(at, 'mike')
      md5_arguments = {:class => "TestClient::QueueWorker", :queue => "customqueue", :args => ['mike']}
      payload_hash = Digest::MD5.hexdigest(Sidekiq.dump_json(md5_arguments))

      # deconstruct this into a time format we can use to get a decent delta for
      actual_expires_at = Sidekiq.redis {|c| c.ttl(payload_hash) }

      assert_in_delta expected_expires_at, actual_expires_at, 2
    end
  end
end
