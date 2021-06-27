# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Reflections do
  let(:reflections) { described_class.new }
  let(:block)       { ->(_item) { "testing" } }
  let(:item)        { { key: "value" } }

  describe "#dispatch" do
    subject(:dispatch) { reflections.dispatch(reflection, item) }

    before do
      reflections.public_send(reflection, &block)
      allow(block).to receive(:call)
      dispatch
    end

    shared_examples "reflects" do
      specify { expect(block).to have_received(:call).with(item) }
    end

    context "when reflecting on :duplicate" do
      let(:reflection) { :duplicate }

      it_behaves_like "reflects"
    end

    context "when reflecting on :error" do
      let(:reflection) { :error }

      it_behaves_like "reflects"
    end

    context "when reflecting on :execution_failed" do
      let(:reflection) { :execution_failed }

      it_behaves_like "reflects"
    end

    context "when reflecting on :locked" do
      let(:reflection) { :locked }

      it_behaves_like "reflects"
    end

    context "when reflecting on :lock_failed" do
      let(:reflection) { :lock_failed }

      it_behaves_like "reflects"
    end

    context "when reflecting on :reschedule_failed" do
      let(:reflection) { :reschedule_failed }

      it_behaves_like "reflects"
    end

    context "when reflecting on :rescheduled" do
      let(:reflection) { :rescheduled }

      it_behaves_like "reflects"
    end

    context "when reflecting on :timeout" do
      let(:reflection) { :timeout }

      it_behaves_like "reflects"
    end

    context "when reflecting on :unlock_failed" do
      let(:reflection) { :unlock_failed }

      it_behaves_like "reflects"
    end

    context "when reflecting on :unlocked" do
      let(:reflection) { :unlocked }

      it_behaves_like "reflects"
    end

    context "when reflecting on :unknown_sidekiq_worker" do
      let(:reflection) { :unknown_sidekiq_worker }

      it_behaves_like "reflects"
    end
  end
end
