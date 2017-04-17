# frozen_string_literal: true

require 'rails_helper'

describe WorkController, 'with real redis' do
  before(:each) do
    SidekiqUniqueJobs.configure do |config|
      config.redis_test_mode = :redis
    end

    Sidekiq::Queues.clear_all
    Sidekiq.redis(&:flushdb)
  end

  describe 'GET /work/duplicate_simple' do
    context 'when test mode is fake', sidekiq: :fake do
      specify do
        expect { get :duplicate_simple, params: { id: 40 } }
          .to change { SimpleWorker.jobs.size }
          .from(0)
          .to(1)
      end
    end

    context 'when test mode is disabled', sidekiq: :disable do
      specify do
        get :duplicate_simple, params: { id: 41 }
        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(1)
        end
      end
    end

    context 'when test mode is inline', sidekiq: :inline do
      specify do
        get :duplicate_simple, params: { id: 42 }
        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(0)
        end
      end
    end
  end

  describe 'GET /work/duplicate_nested' do
    context 'when test mode is fake', sidekiq: :fake do
      specify do
        expect { get :duplicate_nested, params: { id: 34 } }
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
        get :duplicate_nested, params: { id: 35 }

        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(4)
        end
      end
    end

    context 'when test mode is inline', sidekiq: :inline do
      specify do
        get :duplicate_nested, params: { id: 36 }

        Sidekiq.redis do |c|
          expect(c.llen('queue:default')).to eq(0)
        end
      end
    end
  end
end
