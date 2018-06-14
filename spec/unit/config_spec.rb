# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Config do
  let(:args) do
    {

      unique_prefix: 'unique',
      default_lock: :while_executing,
      redis_test_mode: :redis,
    }
  end

  subject do
    described_class.new(args)
  end

  describe '#testing_enabled?' do
    context 'when Sidekiq::Testing is undefined' do
      before { hide_const('Sidekiq::Testing') }
      its(:testing_enabled?) do
        is_expected.to eq(false)
      end
    end

    context 'when Sidekiq::Testing is defined' do
      context 'and Sidekiq::Testing.enabled? is false' do
        before { allow(Sidekiq::Testing).to receive(:enabled?).and_return(false) }
        its(:testing_enabled?) do
          is_expected.to eq(false)
        end
      end

      context 'and Sidekiq::Testing.enabled? is true' do
        before { allow(Sidekiq::Testing).to receive(:enabled?).and_return(true) }
        its(:testing_enabled?) do
          is_expected.to eq(true)
        end
      end
    end
  end

  describe '#inline_testing_enabled?' do
    context 'when testing_enabled? is false' do
      before { allow(subject).to receive(:testing_enabled?).and_return(false) }
      its(:inline_testing_enabled?) do
        is_expected.to eq(false)
      end
    end
    context 'when testing_enabled? is true' do
      before { allow(subject).to receive(:testing_enabled?).and_return(true) }

      context 'and Sidekiq::Testing.inline? is false' do
        before { allow(Sidekiq::Testing).to receive(:inline?).and_return(false) }
        its(:inline_testing_enabled?) do
          is_expected.to eq(false)
        end
      end

      context 'and Sidekiq::Testing.inline? is true' do
        before { allow(Sidekiq::Testing).to receive(:inline?).and_return(true) }
        its(:inline_testing_enabled?) do
          is_expected.to eq(true)
        end
      end
    end
  end

  describe '#mocking?' do
    context 'when redis_test_mode is :redis' do
      its(:mocking?) do
        is_expected.to eq(false)
      end
    end

    context 'when redis_test_mode is :mock' do
      subject { described_class.new(args.merge(redis_test_mode: :mock)) }
      its(:mocking?) do
        is_expected.to eq(true)
      end
    end
  end
end
