# frozen_string_literal: true
require "spec_helper"
RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuting do
  include_context "with a stubbed locksmith"
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> {} }
  let(:item) do
    { "jid" => "maaaahjid",
      "class" => "UntilExpiredJob",
      "lock" => "until_timeout" }
  end

  describe "#execute" do
    it "calls the callback" do
      allow(lock).to receive(:unlock_with_callback)

      expect { |block| lock.execute(&block) }.to yield_control
      expect(lock).to have_received(:unlock_with_callback)
    end
  end
end
