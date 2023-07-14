# frozen_string_literal: true

RSpec.describe BadWorker do
  it do
    expect(described_class).not_to have_valid_sidekiq_options
  end
end
