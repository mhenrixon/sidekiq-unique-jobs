# frozen_string_literal: true

RSpec.describe BadWorker do
  it { expect(described_class).to have_valid_sidekiq_options }
end
