# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'rspec/wait'

RSpec.describe SidekiqUniqueJobs::Client::Middleware, redis: :redis, redis_db: 2 do
  describe '#call' do
    subject { middleware.call(worker_class, item, queue) }

    let(:middleware) { described_class.new }
    let(:worker_class) { SimpleWorker }
    let(:item) do
      { 'class' => SimpleWorker,
        'queue' => queue,
        'args'  => [1] }
    end
    let(:queue) { 'default' }

    context 'when ordinary_or_locked?' do
      before do
        allow(middleware).to receive(:successfully_locked?).and_return(false)
      end

      it { is_expected.to be_nil }
    end
  end
end
