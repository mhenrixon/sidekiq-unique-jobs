# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs do
  describe '.config' do
    subject(:config) { described_class.config }

    it { is_expected.to be_a(Concurrent::MutableStruct::Config) }
    its(:default_lock_timeout)     { is_expected.to eq(0) }
    its(:default_lock)             { is_expected.to eq(:while_executing) }
    its(:enabled)                  { is_expected.to eq(true) }
    its(:raise_unique_args_errors) { is_expected.to eq(false) }
    its(:unique_prefix)            { is_expected.to eq('uniquejobs') }
  end

  describe '.use_config' do
    it 'changes configuration temporary' do
      described_class.use_config(unique_prefix: 'bogus') do
        expect(described_class.config.unique_prefix).to eq('bogus')
      end

      expect(described_class.config.unique_prefix).to eq('uniquejobs')
    end
  end

  describe '.configure' do
    let(:options) { { unique_prefix: 'hi' } }

    context 'when given a block' do
      specify do
        expect { |block| described_class.configure(&block) }.to yield_control
      end

      specify do
        described_class.configure do |config|
          expect(config).to eq(described_class.config)
        end
      end
    end
  end

  describe '.worker_class_constantize' do
    subject(:worker_class_constantize) { described_class.worker_class_constantize(worker_class) }

    context 'when worker_class is nil' do
      let(:worker_class) { nil }

      it { is_expected.to eq(nil) }
    end

    context 'when worker_class is MyUniqueJob' do
      let(:worker_class) { MyUniqueJob }

      it { is_expected.to eq(MyUniqueJob) }
    end

    context 'when worker_class is MyUniqueJob' do
      let(:worker_class) { 'UntilExecutedJob' }

      it { is_expected.to eq(UntilExecutedJob) }
    end

    context 'when NameError is caught' do
      let(:worker_class)  { 'UnknownConstant' }
      let(:error_message) { 'this class does not exist' }

      before do
        allow(Object).to receive(:const_get)
          .with(worker_class)
          .and_raise(NameError, error_message)
      end

      it 'raises NameError' do
        expect { worker_class_constantize }.to raise_error(NameError, error_message)
      end

      context 'when exception.message contains `uninitialized constant`' do
        let(:error_message) { 'uninitialized constant' }

        it { is_expected.to eq('UnknownConstant') }
      end
    end
  end

  describe '.redis_version' do
    subject(:redis_version) { described_class.redis_version }

    it { is_expected.to be_a(String) }
    it { is_expected.to match(/(\d+\.?)+/) }
  end
end
