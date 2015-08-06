require 'spec_helper'
require 'sidekiq/cli'

module SidekiqUniqueJobs
  module Server
    describe Middleware do
      describe '#options' do
        context "when class isn't a Sidekiq::Worker" do
          it 'class defaults are not set' do
            expect(subject.setup_options(Class)).to eq(nil)
          end
        end

        context 'when class is a Sidekiq::Worker' do
          it 'setup_options sets defaults' do
            subject.setup_options(UniqueWorker)
            expect(subject.options).to eq(UniqueWorker.get_sidekiq_options)
          end
        end
      end

      describe '#unlock_order' do
        context 'when worker has specified unique_unlock_order' do
          it 'changes unlock_order to the configured value' do
            test_worker_class = UniqueWorker.dup
            test_worker_class.sidekiq_options unique_unlock_order: :before_yield

            subject.setup_options(test_worker_class)
            expect(subject.unlock_order).to eq :before_yield
          end
        end

        context "when worker hasn't specified unique_unlock_order" do
          it 'falls back to configured default_unlock_order' do
            SidekiqUniqueJobs.config.default_unlock_order = :before_yield
            subject.setup_options(UniqueWorker)
            expect(subject.unlock_order).to eq :before_yield
          end
        end

        context 'when :unique is not used' do
          it 'unlock_order is :never' do
            subject.setup_options(RegularWorker)
            expect(subject.unlock_order).to eq(:never)
          end
        end
      end

      describe '#call' do
        context 'unlock' do
          let(:uj) { SidekiqUniqueJobs::Server::Middleware.new }
          let(:items) { [AfterYieldWorker.new, { 'class' => 'testClass' }, 'fudge'] }

          it 'should unlock after yield when call succeeds' do
            expect(uj).to receive(:unlock)

            uj.call(*items) { true }
          end

          it 'should unlock after yield when call errors' do
            expect(uj).to receive(:unlock)

            expect { uj.call(*items) { fail } }.to raise_error(RuntimeError)
          end

          it 'should not unlock after yield on shutdown, but still raise error' do
            expect(uj).to_not receive(:unlock)

            expect { uj.call(*items) { fail Sidekiq::Shutdown } }.to raise_error(Sidekiq::Shutdown)
          end
        end
      end
    end
  end
end
