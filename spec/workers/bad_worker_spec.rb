# frozen_string_literal: true

require "spec_helper"
RSpec.describe BadWorker do
  xit { expect(described_class).to have_valid_sidekiq_options }
end
