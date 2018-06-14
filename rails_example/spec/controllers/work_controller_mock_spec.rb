# frozen_string_literal: true

require 'rails_helper'

MOCK_REDIS = MockRedis.new

describe WorkController, 'with mock redis', redis: :mock_redis do
  describe 'GET /work/duplicate_simple' do
    context 'when test mode is fake', sidekiq: :fake do
      specify do
        expect { get :duplicate_simple, params: { id: 10 } }
          .to change { SimpleWorker.jobs.size }
          .from(0)
          .to(1)
      end
    end

    context 'when test mode is disabled' do
      let(:expected_keys) do
        %w[
          uniquejobs:5f0092e13b3956c663a91d0d05d10a4b
        ]
      end

      specify do
        get :duplicate_simple, params: { id: 11 }
        Sidekiq.redis do |conn|
          expect(conn.keys).to match_array(expected_keys)
          expect(conn.llen('queue:default')).to eq(0)
        end
      end
    end

    context 'when test mode is inline', sidekiq: :inline do
      specify do
        get :duplicate_simple, params: { id: 12 }
        Sidekiq.redis do |conn|
          expect(conn).to be_a(MockRedis)
          expect(conn.keys.size).to eq(0)
          expect(conn.llen('queue:default')).to eq(0)
        end
      end
    end
  end

  describe 'GET /work/duplicate_nested' do
    context 'when test mode is fake', sidekiq: :fake do
      specify do
        expect { get :duplicate_nested, params: {  id: 20 } }
          .to change { SpawnSimpleWorker.jobs.size }
          .from(0)
          .to(4)

        SpawnSimpleWorker.perform_one
        SpawnSimpleWorker.perform_one
        expect(SpawnSimpleWorker.jobs.size).to eq(2)
        expect(SimpleWorker.jobs.size).to eq(1)
      end
    end

    context 'when test mode is disabled' do
      specify do
        get :duplicate_nested, params: { id: 21 }

        Sidekiq.redis do |conn|
          expect(conn).to be_a(MockRedis)
          expect(conn.keys.size).to eq(0)
          expect(conn.llen('queue:default')).to eq(0)
        end
      end
    end

    context 'when test mode is inline', sidekiq: :inline do
      specify do
        get :duplicate_nested, params: { id: 22 }

        Sidekiq.redis do |conn|
          expect(conn).to be_a(MockRedis)
          expect(conn.keys.size).to eq(0)
          expect(conn.llen('queue:default')).to eq(0)
        end
      end
    end
  end
end
