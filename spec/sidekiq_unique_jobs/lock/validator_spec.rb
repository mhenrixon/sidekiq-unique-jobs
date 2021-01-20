# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::Validator do
  let(:validator) { described_class.new(options) }
  let(:options) do
    {
      "lock" => "until_executed",
      "lock_limit" => 1,
      "lock_timeout" => 0,
      "lock_ttl" => 100,
      "lock_info" => false,
      "on_conflict" => "replace",
    }
  end

  describe "#validate" do
    subject(:validate) { validator.validate }

    context "when lock is until_executed" do
      let(:options) do
        {
          "lock" => "until_executed",
        }
      end

      it { is_expected.to be_valid }
    end

    context "when lock is until_executing" do
      let(:options) do
        {
          "lock" => "until_executing",
        }
      end

      it { is_expected.to be_valid }
    end

    context "when lock is while_executing" do
      let(:options) do
        {
          "lock" => "while_executing",
        }
      end

      it { is_expected.to be_valid }
    end

    context "when lock is until_and_while_executing" do
      let(:options) do
        {
          "lock" => "until_and_while_executing",
        }
      end

      it { is_expected.to be_valid }
    end

    context "with deprecated sidekiq_options" do
      let(:options) do
        {
          "unique" => "until_executed",
          "unique_args" => "hokus",
          "lock_args" => "hokus",
          "unique_prefix" => "pokus",
        }
      end

      it "writes a helpful message about the deprecated key" do
        expect(validate.errors[:unique]).to eq("is deprecated, use `lock: until_executed` instead.")
        expect(validate.errors[:unique_args]).to eq("is deprecated, use `lock_args_method: hokus` instead.")
        expect(validate.errors[:lock_args]).to eq("is deprecated, use `lock_args_method: hokus` instead.")
        expect(validate.errors[:unique_prefix]).to eq("is deprecated, use `lock_prefix: pokus` instead.")
      end
    end
  end
end
