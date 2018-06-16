# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilTimeout, redis: :redis do
  let(:lock) { described_class.new(item) }

  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'UntilExecutedJob',
      'unique' => 'until_timeout' }
  end
  let(:empty_callback) { -> {} }

  describe '#unlock' do
    context 'when provided :server' do
      subject { lock.unlock }

      it { is_expected.to eq(true) }
    end
  end
end
