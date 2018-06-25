# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UntilExpiredJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'lock_expiration' => 1,
        'lock_timeout' => 0,
        'retry'           => true,
        'unique'          => :until_expired,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { 'one' }
  end
end
