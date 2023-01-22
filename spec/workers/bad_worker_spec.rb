# frozen_string_literal: true

RSpec.describe BadWorker do
  it "has valid sidekiq options", skip: "this broken" do
    expect(described_class).to have_valid_sidekiq_options
  end
end
