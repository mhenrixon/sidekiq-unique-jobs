# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UntilExecutingJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue' => :working,
        'retry' => true,
        'lock' => :until_executing,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { no_args }
  end
end
