# frozen_string_literal: true

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
        .to change { described_class.logger }
        .from(original_logger)
        .to(another_logger)

      described_class.logger = original_logger
    end
  end

  describe ".version" do
    subject(:version) { described_class.version }

    it { is_expected.to eq(described_class::VERSION) }
  end

  describe ".enable!" do
    context "when given a block" do
      it "enables unique jobs within the block" do
        described_class.disable!
        expect(described_class.enabled?).to eq(false)

        described_class.enable! do
          expect(described_class.enabled?).to eq(true)
        end

        expect(described_class.enabled?).to eq(false)

        described_class.enable!
      end
    end
  end

  describe ".disable!" do
    context "when given a block" do
      it "disables unique jobs within the block" do
        described_class.enable!
        expect(described_class.disabled?).to eq(false)

        described_class.disable! do
          expect(described_class.disabled?).to eq(true)
        end

        expect(described_class.disabled?).to eq(false)
      end
    end
  end

  describe ".fetch_redis_version" do
    subject(:fetch_redis_version) { described_class.fetch_redis_version }

    it { is_expected.to be_a(String) }
    it { is_expected.to match(/(\d+\.?)+/) }
  end

  describe ".now_f" do
    subject(:now_f) { described_class.now_f }

    let(:frozen_time) { Time.new(2017, 8, 28, 3, 30) }

    it "returns Time.now.to_f" do
      Timecop.freeze(frozen_time) do
        expect(now_f).to eq(frozen_time.to_f)
      end
    end
  end

  describe ".now" do
    subject(:now) { described_class.now }

    let(:frozen_time) { Time.new(2019, 2, 13, 19, 30) }

    it "returns Time.now.to_f" do
      Timecop.freeze(frozen_time) do
        expect(now).to eq(frozen_time)
      end
    end
  end
end
