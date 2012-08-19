require 'helper'
require 'sidekiq/worker'
require "sidekiq-unique-jobs"
require 'sidekiq/scheduled'

class TestClient < MiniTest::Unit::TestCase
  describe 'with real redis' do
    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis {|c| c.flushdb }
    end

    class QueueWorker
      include Sidekiq::Worker
      sidekiq_options :queue => 'customqueue'
      def perform(x)
      end
    end

    it 'does not push duplicate messages when configured for unique only' do
      QueueWorker.sidekiq_options :unique => true
      10.times { Sidekiq::Client.push('class' => QueueWorker, 'args' => [1, 2]) }
      assert_equal 1, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    it 'does push duplicate messages when not configured for unique only' do
      QueueWorker.sidekiq_options :unique => false
      10.times { Sidekiq::Client.push('class' => QueueWorker, 'args' => [1, 2]) }
      assert_equal 10, Sidekiq.redis {|c| c.llen("queue:customqueue") }
    end

    # TODO: If anyone know of a better way to check that the expiration for scheduled
    # jobs are set around the same time as the scheduled job itself feel free to improve.
    it 'expires the payload_hash when a scheduled job is scheduled at' do
      require 'active_support/all'
      QueueWorker.sidekiq_options :unique => true

      at = 15.minutes.from_now
      expected_expires_at = (Time.at(at) - Time.now.utc).to_f

      QueueWorker.perform_in(at, 'mike')
      payload_hash = Digest::MD5.hexdigest(Sidekiq.dump_json(['mike']))

      # deconstruct this into a time format we can use to get a decent delta for
      actual_expires_at = Sidekiq.redis {|c| c.ttl(payload_hash).to_f  / 24 / 60 / 60 }

      assert_in_delta expected_expires_at, actual_expires_at, 0.05

    end
  end
end