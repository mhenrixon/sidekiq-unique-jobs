# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilTimeout do
  subject { described_class.new(item) }
  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'UntilExecutedJob',
      'unique' => 'until_timeout' }
  end
  let(:empty_callback) { -> {} }

  describe '#unlock' do
    context 'when provided :server' do
      it 'returns true' do
        expect(subject.unlock(:server)).to eq(true)
      end
    end

    context 'when provided with anything else than :server' do
      it 'raises a helpful error message' do
        expect { subject.unlock(:client) }
          .to raise_error(ArgumentError, /client middleware can't unlock uniquejobs:*/)
      end
    end
  end
end
