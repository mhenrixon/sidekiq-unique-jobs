# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::SidekiqWorkerMethods do
  class WorkerWithSidekiqMethods
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    def initialize(worker_class)
      @worker_class = worker_class
    end
  end

  let(:worker) { WorkerWithSidekiqMethods.new(worker_class) }

  describe "#worker_class_constantize" do
    subject(:worker_class_constantize) { worker.worker_class_constantize }

    context "when worker_class is nil" do
      let(:worker_class) { nil }

      it { is_expected.to eq(nil) }
    end

    context "when worker_class is MyUniqueJob" do
      let(:worker_class) { MyUniqueJob }

      it { is_expected.to eq(MyUniqueJob) }
    end

    context "when worker_class is MyUniqueJob" do
      let(:worker_class) { "UntilExecutedJob" }

      it { is_expected.to eq(UntilExecutedJob) }
    end

    context "when NameError is caught" do
      let(:worker_class)  { "UnknownConstant" }
      let(:error_message) { "this class does not exist" }

      before do
        allow(Object).to receive(:const_get)
          .with(worker_class)
          .and_raise(NameError, error_message)
      end

      it "raises NameError" do
        expect { worker_class_constantize }.to raise_error(NameError, error_message)
      end

      context "when exception.message contains `uninitialized constant`" do
        let(:error_message) { "uninitialized constant" }

        it { is_expected.to eq("UnknownConstant") }
      end
    end
  end
end
