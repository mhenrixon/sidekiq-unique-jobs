# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UntilTimeoutJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'lock_expiration' => 600,
        'lock_timeout'    => 10,
        'retry'           => true,
        'unique'          => :until_timeout,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { 'one' }
  end
end
