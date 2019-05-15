require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Redis::Entity do
  subject(:entity) { described_class.new(key) }
  let(:key)        { "digest" }

  its(:count) { is_expected.to eq(0) }
end
