# frozen_string_literal: true

RSpec.shared_context "with a stubbed locksmith" do
  let(:locksmith)  { instance_double(SidekiqUniqueJobs::Locksmith) }
  let(:redis_pool) { nil }

  before do
    allow(SidekiqUniqueJobs::Locksmith).to receive(:new).with(item, redis_pool).and_return(locksmith)
  end
end
