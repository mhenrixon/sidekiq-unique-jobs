# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Orphans::Observer do
  let(:observer) { described_class.new }

  describe "#update" do
    subject(:update) { observer.update(time, result, ex) }

    let(:time)   { Time.now }
    let(:ex)     { StandardError.new("we failed") }
    let(:result) { "cool" }

    before do
      allow(observer).to receive(:log_info)
      allow(observer).to receive(:log_warn)
      allow(observer).to receive(:log_error)
    end

    context "when result is present" do
      it "logs an informative message" do
        update

        expect(observer).to have_received(:log_info).with(
          "(#{time}) Execution successfully returned #{result}",
        )
      end
    end

    context "when result is nil" do
      let(:result) { nil }

      context "when ex is Concurrent::TimeoutError" do
        let(:ex) { Concurrent::TimeoutError.new("bogus") }

        it "logs a warning message" do
          update

          expect(observer).to have_received(:log_warn).with("(#{time}) Execution timed out")
        end
      end

      context "when ex is another error" do
        it "logs the exception" do
          update

          expect(observer).to have_received(:log_info).with("(#{time}) Cleanup failed with error #{ex.message}")
          expect(observer).to have_received(:log_error).with(ex)
        end
      end
    end
  end
end
