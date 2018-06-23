# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuted do
  include_context 'with a stubbed locksmith'
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'class' => 'UntilExecutedJob',
      'unique' => 'until_executed',
      'args' => %w[one two],
    }
  end

  describe '#execute' do
    it_behaves_like 'an executing lock with error handling'
  end
end
