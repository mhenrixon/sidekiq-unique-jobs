# frozen_string_literal: true

require 'spec_helper'

RSpec.fdescribe SidekiqUniqueJobs::OptionsWithFallback do
  include described_class
  let(:options_with_fallback) { self }

  describe '#unique_lock' do
    subject { options_with_fallback.unique_lock }

    context 'when options have `unique: true`' do
      let(:options) { { 'unique' => true } }

      it 'warns when unique is set to true' do
        expect(self)
          .to receive(:warn)
          .with(
            'unique: true is no longer valid. Please set it to the type of lock required like: ' \
            '`unique: :until_executed`',
          )

        unique_lock
      end
    end

    context 'when options have `unique: :while_executing`' do
      let(:options) { { 'unique' => :while_executing } }

      pending 'needs a test'
    end
  end

  describe '#unique_enabled?' do
    subject { options_with_fallback.unique_enabled? }

    let(:options) { {} }
    let(:item)    { {} }

    it { is_expected.to eq(nil) }

    context 'when options["unique"] is present' do
      let(:options) { { 'unique' => 'while_executing' } }
      let(:item)    { { 'unique' => 'until_executed' } }

      it { is_expected.to eq('until_executed') }

      context 'when SidekiqUniqueJobs.config.enabled = false' do
        before { SidekiqUniqueJobs.config.enabled = false }
        after  { SidekiqUniqueJobs.config.enabled = true }

        it { is_expected.to eq(false) }
      end
    end

    context 'when item["unique"] is present' do
      let(:options) { {} }
      let(:item)    { { 'unique' => 'until_executed' } }

      it { is_expected.to eq('until_executed') }

      context 'when true' do
        let(:options) { {} }
        let(:item)    { { 'unique' => true } }

        it { is_expected.to eq(true) }

        context 'when SidekiqUniqueJobs.config.enabled = false' do
          before { SidekiqUniqueJobs.config.enabled = false }
          after  { SidekiqUniqueJobs.config.enabled = true }

          it { is_expected.to eq(false) }
        end
      end
    end
  end

  describe '#unique_disabled?' do
    subject { options_with_fallback.unique_disabled? }

    let(:options) { {} }
    let(:item)    { {} }

    it { is_expected.to be_truthy }

    context 'when options["unique"] is present' do
      let(:options) { { 'unique' => 'while_executing' } }
      let(:item)    { { 'unique' => 'until_executed' } }

      it { is_expected.to be_falsey }
    end

    context 'when item["unique"] is present' do
      let(:options) { {} }
      let(:item)    { { 'unique' => 'until_executed' } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#lock_type' do
    subject { options_with_fallback.lock_type }

    context 'when options["unique"] is while_executing' do
      let(:options) { { 'unique' => 'while_executing' } }
      let(:item)    { { 'unique' => 'until_executed' } }

      it { is_expected.to eq('while_executing') }
    end

    context 'when options["unique"] is true' do
      let(:options) { { 'unique' => true } }
      let(:item)    { { 'unique' => 'until_executed' } }

      it { is_expected.to eq('until_executed') }
    end

    context 'when item["unique"] is until_executed' do
      let(:options) { {} }
      let(:item)    { { 'unique' => 'until_executed' } }

      it { is_expected.to eq('until_executed') }
    end

    context 'when item["unique"] is true' do
      let(:options) { { 'unique' => true } }
      let(:item)    { { 'unique' => true } }

      it { is_expected.to eq(nil) }
    end
  end

  describe '#options' do
    subject { options_with_fallback.options }

    context 'when worker_class respond_to get_sidekiq_options' do
      let(:worker_class) { SimpleWorker }

      it { is_expected.to eq(SimpleWorker.get_sidekiq_options) }
    end

    context 'when default_worker_options has been configured' do
      let(:worker_class) { PlainClass }

      before do
        allow(Sidekiq)
          .to receive(:default_worker_options)
          .and_return('unique' => 'while_executing')
      end

      it { is_expected.to eq(Sidekiq.default_worker_options) }
    end
  end
end
