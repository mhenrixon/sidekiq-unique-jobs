require 'helper'
require 'celluloid'
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

    class PlainClass
      def run(x)
      end
    end

    it 'does not push duplicate messages when configured for unique only' do
      QueueWorker.sidekiq_options :unique => true
      10.times { Sidekiq::Client.push('class' => TestClient::QueueWorker, 'queue' => 'customqueue',  'args' => [1, 2]) }
      assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    it 'does not queue duplicates when when calling delay' do
      10.times { PlainClass.delay(unique: true, queue: 'customqueue').run(1) }
      assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    it 'does not schedule duplicates when calling perform_in' do
      QueueWorker.sidekiq_options :unique => true
      10.times { QueueWorker.perform_in(60, [1, 2]) }
      assert_equal 1, Sidekiq.redis { |c| c.zcount("schedule", -1, Time.now.to_f + 2 * 60) }
    end

    it 'enqueues previously scheduled job' do
      QueueWorker.sidekiq_options :unique => true
      QueueWorker.perform_in(60 * 60, 1, 2)

      # time passes and the job is pulled off the schedule:
      Sidekiq::Client.push('class' => TestClient::QueueWorker, 'queue' => 'customqueue', 'args' => [1, 2])

      assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    it 'sets an expiration when provided by sidekiq options' do
      one_hour_expiration = 60 * 60
      QueueWorker.sidekiq_options :unique => true, :unique_job_expiration => one_hour_expiration
      Sidekiq::Client.push('class' => TestClient::QueueWorker, 'queue' => 'customqueue',  'args' => [1, 2])

      payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload("TestClient::QueueWorker", "customqueue", [1, 2])
      actual_expires_at = Sidekiq.redis {|c| c.ttl(payload_hash) }

      assert_in_delta one_hour_expiration, actual_expires_at, 2
    end

    it 'does push duplicate messages when not configured for unique only' do
      QueueWorker.sidekiq_options :unique => false
      10.times { Sidekiq::Client.push('class' => TestClient::QueueWorker, 'queue' => 'customqueue',  'args' => [1, 2]) }
      assert_equal 10, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    describe 'when unique_args is defined' do
      before { SidekiqUniqueJobs::Config.unique_args_enabled = true }
      after  { SidekiqUniqueJobs::Config.unique_args_enabled = false }

      class QueueWorkerWithFilterMethod < QueueWorker
        sidekiq_options :unique => true, :unique_args => :args_filter

        def self.args_filter(*args)
          args.first
        end
      end

      class QueueWorkerWithFilterProc < QueueWorker
        # slightly contrived example of munging args to the worker and removing a random bit.
        sidekiq_options :unique => true, :unique_args => lambda { |args| a = args.last.dup; a.delete(:random); [ args.first, a ] }
      end

      it 'does not push duplicate messages based on args filter method' do
        assert TestClient::QueueWorkerWithFilterMethod.respond_to?(:args_filter)
        assert_equal :args_filter, TestClient::QueueWorkerWithFilterMethod.get_sidekiq_options['unique_args']

        for i in (0..10).to_a
          Sidekiq::Client.push('class' => TestClient::QueueWorkerWithFilterMethod, 'queue' => 'customqueue', 'args' => [1, i])
        end
        assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
      end

      it 'does not push duplicate messages based on args filter proc' do
        assert_kind_of Proc, TestClient::QueueWorkerWithFilterProc.get_sidekiq_options['unique_args']

        10.times do
          Sidekiq::Client.push('class' => TestClient::QueueWorkerWithFilterProc, 'queue' => 'customqueue', 'args' => [ 1, {:random => rand(), :name => "foobar"} ])
        end
        assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
      end
    end

    # TODO: If anyone know of a better way to check that the expiration for scheduled
    # jobs are set around the same time as the scheduled job itself feel free to improve.
    it 'expires the payload_hash when a scheduled job is scheduled at' do
      require 'active_support/all'
      QueueWorker.sidekiq_options :unique => true

      at = 15.minutes.from_now
      expected_expires_at = (Time.at(at) - Time.now.utc) + SidekiqUniqueJobs::Config.default_expiration

      QueueWorker.perform_in(at, 'mike')
      payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload("TestClient::QueueWorker", "customqueue", ['mike'])

      # deconstruct this into a time format we can use to get a decent delta for
      actual_expires_at = Sidekiq.redis {|c| c.ttl(payload_hash) }

      assert_in_delta expected_expires_at, actual_expires_at, 2
    end
  end
end
