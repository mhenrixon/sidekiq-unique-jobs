# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::OnConflict::Raise do
  let(:strategy)      { described_class.new(item) }
  let(:unique_digest) { 'uniquejobs:random-digest-value' }
  let(:item) do
    { 'unique_digest' => unique_digest }
  end

  describe '#call' do
    let(:call) { strategy.call }

    it do
      expect { call }.to raise_error(
        SidekiqUniqueJobs::Conflict,
        'Item with the key: uniquejobs:random-digest-value is already scheduled or processing',
      )
    end
  end
end
