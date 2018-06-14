# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AnotherUniqueJob do
  it_behaves_like 'sidekiq with options', options: {
    'queue'     => :working2,
    'retry'     => 1,
    'backtrace' => 10,
    'unique'    => :until_executed,
  }

  it_behaves_like 'a performing worker', args: 'one'
end
