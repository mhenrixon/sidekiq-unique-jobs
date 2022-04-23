# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::SidekiqWorkerMethods do
  let(:custom_job_class) do
    Class.new do
      include SidekiqUniqueJobs::SidekiqWorkerMethods

      def initialize(job_class)
        self.job_class = job_class
      end
    end
  end

  let(:job) { custom_job_class.new(job_class) }

  describe "#job_class_constantize" do
    subject(:job_class_constantize) { job.job_class_constantize }

    context "when job_class is nil" do
      let(:job_class) { nil }

      it { is_expected.to be_nil }
    end

    context "when job_class is MyUniqueJob" do
      let(:job_class) { MyUniqueJob }

      it { is_expected.to eq(MyUniqueJob) }
    end

    context "when job_class is instance of UntilExecutedJob" do
      let(:job_class) { UntilExecutedJob.new }

      it { is_expected.to eq(UntilExecutedJob) }
    end

    context "when job_class is UntilExecutedJob" do
      let(:job_class) { "UntilExecutedJob" }

      it { is_expected.to eq(UntilExecutedJob) }
    end

    context "when NameError is caught", ruby_ver: "< 3.0" do
      let(:job_class) { "UnknownConstant" }
      let(:error_message) { "this class does not exist" }

      before do
        allow(Object).to receive(:const_get)
          .with(job_class)
          .and_raise(NameError, error_message)
      end

      it "raises NameError" do
        expect { job_class_constantize }.to raise_error(NameError, error_message)
      end

      context "when exception.message contains `uninitialized constant`" do
        let(:error_message) { "uninitialized constant" }

        it { is_expected.to eq("UnknownConstant") }
      end
    end
  end

  describe "#job_options" do
    subject(:job_options) { job.job_options }

    let(:job_class) { UniqueJobOnConflictHash }

    it do
      expect(job_options).to match(
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
