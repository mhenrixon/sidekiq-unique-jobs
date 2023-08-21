# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockDigest, perf: true do
  let(:service)    { described_class.new(item) }
  let(:job_class)  { UntilExecutedJob }
  let(:class_name) { job_class.to_s }
  let(:queue)      { "myqueue" }
  let(:args)       { [[1, 2]] }
  let(:item) do
    {
      "class" => class_name,
      "queue" => queue,
      "args" => args,
    }
  end

  describe "#lock_digest" do
    subject(:lock_digest) { service.lock_digest }

    it "performs in under 0.1 ms" do
      expect { lock_digest }.to perform_under(0.1).ms
    end

    context "when args are empty" do
      let(:another_lock_digest) { described_class.new(item) }
      let(:job_class)           { WithoutArgumentJob }
      let(:args)                { [] }

      it "performs in under 0.1 ms" do
        expect { lock_digest }.to perform_under(0.1).ms
      end
    end

    context "when unique_args is a proc" do
      let(:job_class) { MyUniqueJobWithFilterProc }
      let(:args) { [1, 2, { "type" => "it" }] }

      it "performs in under 0.1 ms" do
        expect { lock_digest }.to perform_under(0.1).ms
      end
    end

    context "when unique_args is a symbol" do
      let(:job_class) { MyUniqueJobWithFilterMethod }
      let(:args) { [1, 2, { "type" => "it" }] }

      it "performs in under 0.1 ms" do
        expect { lock_digest }.to perform_under(0.1).ms
      end
    end
  end
end
