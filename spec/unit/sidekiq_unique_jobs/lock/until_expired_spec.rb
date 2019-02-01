# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Lock::UntilExpired do
  include_context "with a stubbed locksmith"
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> {} }
  let(:item) do
    { "jid" => "maaaahjid",
      "class" => "UntilExpiredJob",
      "lock" => "until_timeout" }
  end

  before do
    allow(callback).to receive(:call)
  end

  describe "#unlock" do
    subject(:unlock) { lock.unlock }

    it { is_expected.to eq(true) }
  end

  describe "#execute" do
    subject(:execute) { lock.execute(&block) }

    let(:locked?) { false }

    before do
      allow(lock).to receive(:locked?).and_return(locked?)
    end

    context "when locked?" do
      let(:locked?) { true }

      it "yields to caller" do
        expect { |block| lock.execute(&block) }.to yield_control
      end
    end

    context "when not locked?" do
      it "does not yield to caller" do
        expect { |block| lock.execute(&block) }.not_to yield_control
      end
    end
  end
end
