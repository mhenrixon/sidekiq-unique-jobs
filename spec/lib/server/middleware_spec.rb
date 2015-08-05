require 'spec_helper'
require 'sidekiq/cli'

module SidekiqUniqueJobs
  module Server
    describe Middleware do
      describe '#unlock_order_configured?' do
        context "when class isn't a Sidekiq::Worker" do
          it 'class defaults are not set' do
            expect(subject.setup_options(Class)).to eq(nil)
          end
        end
      end

      describe '#decide_unlock_order' do
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
      end

      describe 'on :after_yield' do
        it '#after_yield_call is called' do
          allow(subject).to receive(:unlock_order).and_return(:after_yield)
          #expect(subject.call).to call(:after_yield_call)
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
