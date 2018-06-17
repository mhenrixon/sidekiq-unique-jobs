# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniqueJobWithNoUniqueArgsMethod do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'backtrace'   => true,
        'queue'       => :customqueue,
        'retry'       => true,
        'unique'      => :until_executed,
        'unique_args' => :filtered_args,
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { %w[one two] }
  end
end
