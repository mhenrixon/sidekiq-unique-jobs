# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs do
  describe ".config" do
    subject(:config) { described_class.config }

    it { is_expected.to be_a(SidekiqUniqueJobs::Config) }
    its(:default_lock_timeout)     { is_expected.to eq(0) }
    its(:enabled)                  { is_expected.to eq(true) }
    its(:unique_prefix)            { is_expected.to eq("uniquejobs") }
  end

  describe ".use_config" do
    it "changes configuration temporary" do
      described_class.use_config(unique_prefix: "bogus") do
        expect(described_class.config.unique_prefix).to eq("bogus")
      end

      expect(described_class.config.unique_prefix).to eq("uniquejobs")
    end
  end

  describe ".configure" do
    let(:options) { { unique_prefix: "hi" } }

    context "when given a block" do
      specify do
        expect { |block| described_class.configure(&block) }.to yield_control
      end

      specify do
        described_class.configure do |config|
          expect(config).to eq(described_class.config)
        end
      end
    end
  end

  describe ".logger" do
    subject { described_class.logger }

    context "without further configuration" do
      it { is_expected.to eq(Sidekiq.logger) }
    end

    context "when configured explicitly" do
      let(:another_logger) { Logger.new("/dev/null") }

      around do |exmpl|
        described_class.use_config(logger: another_logger) do
          exmpl.run
        end
      end

      it { is_expected.to eq(another_logger) }
    end
  end

  describe ".logger=" do
    let(:original_logger) { Sidekiq.logger }
    let(:another_logger)  { Logger.new("/dev/null") }

    it "changes the SidekiqUniqueJobs.logger" do
      expect { described_class.logger = another_logger }
        .to change(described_class, :logger)
        .from(original_logger)
        .to(another_logger)

      described_class.logger = original_logger
    end
  end

  describe ".redis_version" do
    subject(:redis_version) { described_class.redis_version }

    it { is_expected.to be_a(String) }
    it { is_expected.to match(/(\d+\.?)+/) }
  end
end
