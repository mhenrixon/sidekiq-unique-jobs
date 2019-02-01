# frozen_string_literal: true

require "spec_helper"

require "sidekiq/worker"
require "sidekiq-unique-jobs"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe SidekiqUniqueJobs::Client::Middleware do
  let(:middleware) { described_class.new }

  describe "#call" do
    subject(:call) { middleware.call(worker_class, item, queue, &block) }

    let(:block)        { -> { @inside_block_value = true } }
    let(:worker_class) { SimpleWorker }
    let(:queue)        { "default" }
    let(:item) do
      { "class" => SimpleWorker,
        "queue" => queue,
        "args" => [1] }
    end

    before { @inside_block_value = false }

    context "when locking succeeds" do
      before do
        allow(middleware).to receive(:locked?).and_return(true)
      end

      it "yields control" do
        expect { call }.to change { @inside_block_value }.to(true)
      end
    end

    context "when already locked" do
      before do
        allow(middleware).to receive(:locked?).and_return(false)
      end

      it "does not yield control" do
        expect { call }.not_to change { @inside_block_value }.from(false)
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
