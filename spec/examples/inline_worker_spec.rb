# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InlineWorker do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'lock_timeout' => 5,
        'retry'        => true,
        'lock' => :while_executing,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { 'one' }
  end
end
