# frozen_string_literal: true

# rubocop:disable RSpec/InstanceVariable
RSpec.describe SidekiqUniqueJobs::Server::Middleware do
  let(:middleware) { described_class.new }

  describe "#call" do
    subject(:call) { middleware.call(worker_class, item, queue, &block) }

    let(:block)        { -> { @inside_block_value = true } }
    let(:worker_class) { WhileExecutingJob }
    let(:queue)        { "working" }
    let(:redis_pool)   { nil }
    let(:args)         { [1] }
    let(:item) do
      { "class" => worker_class,
        "queue" => queue,
        "args" => args }
    end
    let(:lock) { instance_spy(SidekiqUniqueJobs::Lock::WhileExecuting) }

    before do
      @inside_block_value = false
      allow(middleware).to receive(:lock).and_return(lock)
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
end
# rubocop:enable RSpec/InstanceVariable
