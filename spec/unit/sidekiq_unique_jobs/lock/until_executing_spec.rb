# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuting do
  include_context 'with a stubbed locksmith'

  let(:item) do
    { 'jid' => 'maaaahjid',
      'class' => 'UntilExpiredJob',
      'unique' => 'until_timeout' }
  end
  let(:empty_callback) { -> {} }

  describe '#execute' do
    it 'calls the callback' do
      expect(lock).to receive(:unlock).ordered
      expect(empty_callback).to receive(:call)
      expect { |block| lock.execute(empty_callback, &block) }.to yield_control
    end
  end
end
