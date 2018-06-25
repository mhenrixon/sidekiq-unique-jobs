# frozen_string_literal: true

RSpec.shared_examples 'sidekiq with options' do
  subject(:sidekiq_options) { described_class.get_sidekiq_options }

  it { is_expected.to match(a_hash_including(options)) }
end
