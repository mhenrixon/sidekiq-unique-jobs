# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::OptionsWithFallback do
  class ClassWithOptions
    include SidekiqUniqueJobs::OptionsWithFallback

    attr_reader :item, :worker_class

    def initialize(item, options, worker_class = nil)
      @item         = item
      @options      = options
      @worker_class = worker_class
    end
  end
  let(:options_with_fallback) { ClassWithOptions.new(item, options, worker_class) }
  let(:item)                  { {} }
  let(:options)               { nil }
  let(:worker_class)          { nil }

  describe '#unique_lock' do
    subject(:unique_lock) { options_with_fallback.unique_lock }

    context 'when options["unique"] is present' do
      let(:options) { { 'unique' => :while_executing } }
      let(:item)    { { 'unique' => :until_executed } }

      it { is_expected.to eq(:while_executing) }

      context 'when true' do
        let(:options) { { 'unique' => true } }

        it 'warns when unique is set to true' do
          expect(options_with_fallback)
            .to receive(:warn)
            .with(
              'unique: true is no longer valid. Please set it to the type of lock required like: ' \
              '`unique: :until_executed`',
            )

          unique_lock
        end
      end
    end

    context 'when item["unique"] is present' do
      let(:options) { {} }
      let(:item)    { { 'unique' => :until_executed } }

      it { is_expected.to eq(:until_executed) }
    end
  end

  describe '#unique_enabled?' do
    subject { options_with_fallback.unique_enabled? }

    let(:options) { {} }
    let(:item)    { {} }

    it { is_expected.to eq(nil) }

    context 'when options["unique"] is present' do
      let(:options) { { 'unique' => :while_executing } }
      let(:item)    { { 'unique' => :until_executed } }

      it { is_expected.to eq(:until_executed) }

      context 'when SidekiqUniqueJobs.config.enabled = false' do
        before { SidekiqUniqueJobs.config.enabled = false }
        after  { SidekiqUniqueJobs.config.enabled = true }

        it { is_expected.to eq(false) }
      end
    end

    context 'when item["unique"] is present' do
      let(:options) { nil }
      let(:item)    { { 'unique' => :until_executed } }

      it { is_expected.to eq(:until_executed) }

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
      let(:worker_class)           { PlainClass }
      let(:default_worker_options) { { 'unique' => :while_executing } }

      it do
        with_default_worker_options(default_worker_options) do
          is_expected.to include(default_worker_options)
        end
      end
    end
  end
end
