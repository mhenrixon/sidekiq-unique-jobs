# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::UniqueArgs, perf: true do
  let(:unique_args)  { described_class.new(item) }
  let(:worker_class) { UntilExecutedJob }
  let(:class_name)   { worker_class.to_s }
  let(:queue)        { "myqueue" }
  let(:args)         { [[1, 2]] }
  let(:item) do
    {
      "class" => class_name,
      "queue" => queue,
      "args" => args,
    }
  end

  describe "#unique_digest" do
    subject(:unique_digest) { unique_args.unique_digest }

    it "performs in under 0.1 ms" do
      expect { unique_digest }.to perform_under(0.1).ms
    end

    context "when args are empty" do
      let(:another_unique_args) { described_class.new(item) }
      let(:worker_class)        { WithoutArgumentJob }
      let(:args)                { [] }

      it "performs in under 0.1 ms" do
        expect { unique_digest }.to perform_under(0.1).ms
      end
    end

    context "when unique_args is a proc" do
      let(:worker_class) { MyUniqueJobWithFilterProc }
      let(:args)         { [1, 2, "type" => "it"] }

      it "performs in under 0.1 ms" do
        expect { unique_digest }.to perform_under(0.1).ms
      end
    end

    context "when unique_args is a symbol" do
      let(:worker_class) { MyUniqueJobWithFilterMethod }
      let(:args)         { [1, 2, "type" => "it"] }

      it "performs in under 0.1 ms" do
        expect { unique_digest }.to perform_under(0.1).ms
      end
    end
  end
end
