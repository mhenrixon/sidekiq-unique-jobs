# frozen_string_literal: true
require "sidekiq-unique-jobs"

RSpec.describe SidekiqUniqueJobs::Middleware::Client, "#call" do
  subject(:call) { middleware.call(job_class, item, queue, &block) }

  let(:middleware) { described_class.new }
  let(:block)      { -> { @inside_block_value = true } }
  let(:job_class)  { SimpleWorker }
  let(:queue)      { "default" }
  let(:item) do
    { "class" => SimpleWorker,
      "queue" => queue,
      "args" => [1] }
  end

  before { @inside_block_value = false }

  context "when locking succeeds" do
    before do
      allow(middleware).to receive(:lock).and_yield
    end

    it "yields control" do
      expect { call }.to change { @inside_block_value }.to(true)
    end
  end

  context "when already locked" do
    before do
      allow(middleware).to receive(:lock)
    end

    it "does not yield control" do
      expect { call }.not_to change { @inside_block_value }.from(false)
    end
  end
end
