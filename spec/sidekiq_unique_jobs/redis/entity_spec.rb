# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Redis::Entity do
  subject(:entity) { described_class.new(key) }

  let(:key)        { "digest" }

  its(:count) { is_expected.to eq(0) }
end
