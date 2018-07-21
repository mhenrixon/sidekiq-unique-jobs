# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WithoutArgumentJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'log_duplicate_payload' => true,
        'retry'                 => true,
        'lock' => :until_executed,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { no_args }
  end
end
