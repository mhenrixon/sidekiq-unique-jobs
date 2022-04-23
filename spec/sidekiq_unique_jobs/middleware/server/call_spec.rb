# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Middleware::Server, "#call" do
  subject(:call) { middleware.call(job_class, item, queue, &block) }

  let(:middleware) { described_class.new }
  let(:block)      { -> { @inside_block_value = true } }
  let(:job_class)  { WhileExecutingJob }
  let(:queue)      { "working" }
  let(:redis_pool) { nil }
  let(:args)       { [1] }
  let(:lock)       { instance_spy(SidekiqUniqueJobs::Lock::WhileExecuting) }
  let(:item) do
    { "class" => job_class,
      "queue" => queue,
      "args" => args }
  end

  before do
    @inside_block_value = false
    allow(middleware).to receive(:lock_instance).and_return(lock)
    allow(lock).to receive(:execute).and_yield
  end

  context "when unique is disabled" do
    before do
      allow(middleware).to receive(:unique_enabled?).and_return(false)
    end

    it "yields control" do
      expect { call }.to change { @inside_block_value }.to(true)
    end
  end

  context "when unique is enabled" do
    before do
      allow(middleware).to receive(:unique_enabled?).and_return(true)
    end

    it "yields control" do
      expect { call }.to change { @inside_block_value }.to(true)
    end
  end
end
