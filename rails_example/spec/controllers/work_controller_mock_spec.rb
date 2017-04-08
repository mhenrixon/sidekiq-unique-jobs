require 'rails_helper'

MOCK_REDIS = MockRedis.new

describe WorkController, "with mock redis" do
  before do
    MOCK_REDIS.keys.each do |key|
      MOCK_REDIS.del(key)
    end

    Sidekiq::Queues.clear_all
    Sidekiq::Worker.clear_all

    SidekiqUniqueJobs.configure do |config|
      config.redis_test_mode = :mock
    end
    allow(Sidekiq).to receive(:redis).and_yield(MOCK_REDIS)
  end

  describe 'GET /work/duplicate_simple' do
    context 'when test mode is fake', sidekiq: :fake do
      specify do
        expect { get :duplicate_simple, params: {  id:10 } }
          .to change { SimpleWorker.jobs.size }
          .from(0)
          .to(1)
      end
    end

    context 'when test mode is disabled', sidekiq: :disable do
      specify do
        get :duplicate_simple, params: { id: 11 }
        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(1)
        end
      end
    end

    context 'when test mode is inline', sidekiq: :inline do
      specify do
        get :duplicate_simple, params: { id: 12 }
        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(0)
        end
      end
    end
  end

  describe 'GET /work/duplicate_nested' do
    context 'when test mode is fake', sidekiq: :fake do
      specify do
        expect { get :duplicate_nested, params: {  id:20 } }
          .to change { SpawnSimpleWorker.jobs.size }
          .from(0)
          .to(4)

        SpawnSimpleWorker.perform_one
        SpawnSimpleWorker.perform_one
        expect(SpawnSimpleWorker.jobs.size).to eq(2)
        expect(SimpleWorker.jobs.size).to eq(1)
      end
    end

    context 'when test mode is disabled', sidekiq: :disable do
      specify do
        get :duplicate_nested, params: { id: 21 }

        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(4)
        end
      end
    end

    context 'when test mode is inline', sidekiq: :inline do
      specify do
        get :duplicate_nested, params: { id: 22 }

        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(0)
        end
      end
    end
  end
end
