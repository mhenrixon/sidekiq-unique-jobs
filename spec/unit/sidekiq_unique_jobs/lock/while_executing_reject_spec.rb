# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecutingReject do
  include_context "with a stubbed locksmith"
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> {} }
  let(:item) do
    { "jid" => "maaaahjid",
      "class" => "WhileExecutingRejectJob",
      "lock" => "while_executing_reject",
      "args" => [%w[array of arguments]] }
  end

  before do
    allow(lock).to receive(:unlock)
  end

  describe "#lock" do
    subject { lock.lock }

    it { is_expected.to eq(true) }
  end

  describe "#execute" do
    subject(:execute) { lock.execute {} }

    let(:token) { nil }

    before do
      allow(locksmith).to receive(:lock).with(0).and_return(token)
      allow(lock).to receive(:with_cleanup).and_yield
    end

    context "when lock succeeds" do
      let(:token) { "a token" }

      it "processes the job" do
        execute
        expect(lock).to have_received(:with_cleanup)
      end
    end

    context "when lock fails" do
      let(:token) { nil }

      it "rejects the job" do
        execute

        expect(lock).not_to have_received(:with_cleanup)
      end
    end
  end
end
