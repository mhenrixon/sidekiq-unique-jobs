# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomQueueJobWithFilterProc do
  it_behaves_like 'sidekiq with options' do
    let(:options) do
      {
        'queue' => :customqueue,
        'retry' => true,
        'lock' => :until_expired,
        'unique_args' => a_kind_of(Proc),
      }
    end
  end

  it_behaves_like 'a performing worker' do
    let(:args) { [1, 'random' => rand, 'name' => 'foobar'] }
  end
end
