# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::OptionsWithFallback do
  include described_class
  subject(:options_with_fallback) { self }

  describe '#unique_lock' do
    context 'when options have `unique: true`' do
      let(:options) { { 'unique' => true } }

      it 'warns when unique is set to true' do
        expect(self)
          .to receive(:warn)
          .with(
            'unique: true is no longer valid. Please set it to the type of lock required like: ' \
            '`unique: :until_executed`',
          )

        options_with_fallback.unique_lock
      end
    end

    context 'when options have `unique: :while_executing`' do
      let(:options) { { 'unique' => 'while_executing' } }

      pending 'needs a test'
    end
  end

  describe '#unique_enabled?' do
    let(:options) { {} }
    let(:item) { {} }

    its(:unique_enabled?) { is_expected.to eq(nil) }

    context 'when options["unique"] is present' do
      let(:options) { { 'unique' => 'while_executing' } }
      let(:item) { { 'unique' => 'until_executed' } }

      its(:unique_enabled?) { is_expected.to eq('until_executed') }
    end

    context 'when item["unique"] is present' do
      let(:options) { {} }
      let(:item) { { 'unique' => 'until_executed' } }

      its(:unique_enabled?) { is_expected.to eq('until_executed') }

      context 'when true' do
        let(:options) { {} }
        let(:item) { { 'unique' => true } }

        its(:unique_enabled?) { is_expected.to eq(true) }
      end
    end
  end

  describe '#unique_disabled?' do
    let(:options) { {} }
    let(:item) { {} }

    its(:unique_disabled?) { is_expected.to be_truthy }

    context 'when options["unique"] is present' do
      let(:options) { { 'unique' => 'while_executing' } }
      let(:item) { { 'unique' => 'until_executed' } }

      its(:unique_disabled?) { is_expected.to be_falsey }
    end

    context 'when item["unique"] is present' do
      let(:options) { {} }
      let(:item) { { 'unique' => 'until_executed' } }

      its(:unique_disabled?) { is_expected.to be_falsey }
    end
  end

  describe '#lock_type' do
    context 'when options["unique"] is while_executing' do
      let(:options) { { 'unique' => 'while_executing' } }
      let(:item) { { 'unique' => 'until_executed' } }

      its(:lock_type) { is_expected.to eq('while_executing') }
    end

    context 'when options["unique"] is true' do
      let(:options) { { 'unique' => true } }
      let(:item) { { 'unique' => 'until_executed' } }

      its(:lock_type) { is_expected.to eq('until_executed') }
    end

    context 'when item["unique"] is until_executed' do
      let(:options) { {} }
      let(:item) { { 'unique' => 'until_executed' } }

      its(:lock_type) { is_expected.to eq('until_executed') }
    end

    context 'when item["unique"] is true' do
      let(:options) { { 'unique' => true } }
      let(:item) { { 'unique' => true } }

      its(:lock_type) { is_expected.to eq(nil) }
    end
  end

  describe '#options' do
    context 'when worker_class respond_to get_sidekiq_options' do
      let(:worker_class) { SimpleWorker }

      its(:options) { is_expected.to eq(SimpleWorker.get_sidekiq_options) }
    end

    context 'when default_worker_options has been configured' do
      let(:worker_class) { PlainClass }

      before do
        allow(Sidekiq)
          .to receive(:default_worker_options)
          .and_return('unique' => 'while_executing')
      end

      its(:options) { is_expected.to eq(Sidekiq.default_worker_options) }
    end
  end
end
