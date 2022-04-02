# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::SidekiqWorkerMethods do
  let(:custom_worker_class) do
    Class.new do
      include SidekiqUniqueJobs::SidekiqWorkerMethods

      def initialize(worker_class)
        @worker_class = worker_class
      end
    end
  end

  let(:worker) { custom_worker_class.new(worker_class) }

  describe "#worker_class_constantize" do
    subject(:worker_class_constantize) { worker.worker_class_constantize }

    context "when worker_class is nil" do
      let(:worker_class) { nil }

      it { is_expected.to be_nil }
    end

    context "when worker_class is MyUniqueJob" do
      let(:worker_class) { MyUniqueJob }

      it { is_expected.to eq(MyUniqueJob) }
    end

    context "when worker_class is instance of UntilExecutedJob" do
      let(:worker_class) { UntilExecutedJob.new }

      it { is_expected.to eq(UntilExecutedJob) }
    end

    context "when worker_class is UntilExecutedJob" do
      let(:worker_class) { "UntilExecutedJob" }

      it { is_expected.to eq(UntilExecutedJob) }
    end

    context "when NameError is caught", ruby_ver: "< 3.0" do
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

  describe "#worker_options" do
    subject(:worker_options) { worker.worker_options }

    let(:worker_class) { UniqueJobOnConflictHash }

    it do
      expect(worker_options).to match(
        hash_including(
          "lock" => :until_and_while_executing,
          "on_conflict" => {
            "client" => :log,
            "server" => :reschedule,
          },
          "queue" => :customqueue,
          "retry" => true,
        ),
      )
    end
  end
end
