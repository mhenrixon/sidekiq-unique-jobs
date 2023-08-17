# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::OnConflict::Reject do
  include_context "with a stubbed locksmith"
  let(:strategy) { described_class.new(item) }
  let(:deadset)  { instance_spy(Sidekiq::DeadSet) }
  let(:payload)  { instance_spy(String) }
  let(:item) do
    { "jid" => "maaaahjid",
      "class" => "WhileExecutingRejectJob",
      "lock" => "while_executing_reject",
      "args" => [%w[array of arguments]] }
  end

  before do
    allow(strategy).to receive_messages(deadset: deadset, payload: payload)
  end

  describe "#replace?" do
    subject { strategy.replace? }

    it { is_expected.to be(false) }
  end

  describe "#call" do
    subject(:call) { strategy.call }

    context "when kill_with_options?" do
      before do
        allow(strategy).to receive(:kill_with_options?).and_return(true)
        allow(strategy).to receive(:kill_job_with_options)
        call
      end

      it "calls kill_job_with_options" do
        expect(strategy).to have_received(:kill_job_with_options)
      end
    end

    context "when not kill_with_options?" do
      before do
        allow(strategy).to receive(:kill_with_options?).and_return(false)
        allow(strategy).to receive(:kill_job_without_options)
        call
      end

      it "calls kill_job_without_options" do
        expect(strategy).to have_received(:kill_job_without_options)
      end
    end
  end

  describe "#kill_job_with_options" do
    subject(:kill_job_with_options) { strategy.kill_job_with_options }

    before do
      allow(deadset).to receive(:kill)
      kill_job_with_options
    end

    it "calls deadset.kill with options hash" do
      expect(deadset).to have_received(:kill).with(payload, notify_failure: false)
    end
  end
end
