# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UntilAndWhileExecutingJob do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue'  => :working,
        'retry'  => true,
        'unique' => :until_and_while_executing,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { [%w[one]] }
  end
end
