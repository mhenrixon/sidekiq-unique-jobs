# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Script::Logging do
  before do
    stub_const("LoggingClass", Class.new do
      include SidekiqUniqueJobs::Script::Logging
    end)
  end

  describe "#methods" do
    subject(:logging_impl) { LoggingClass.new }

    it { is_expected.to respond_to(:logger) }
    it { is_expected.to respond_to(:log_debug).with(1).arguments }
    it { is_expected.to respond_to(:log_info).with(1).arguments }
    it { is_expected.to respond_to(:log_warn).with(1).arguments }
    it { is_expected.to respond_to(:log_error).with(1).arguments }
    it { is_expected.to respond_to(:log_fatal).with(1).arguments }
  end

  describe ".methods" do
    subject(:logging_impl) { LoggingClass }

    it { is_expected.to respond_to(:logger) }
    it { is_expected.to respond_to(:log_debug).with(1).arguments }
    it { is_expected.to respond_to(:log_info).with(1).arguments }
    it { is_expected.to respond_to(:log_warn).with(1).arguments }
    it { is_expected.to respond_to(:log_error).with(1).arguments }
    it { is_expected.to respond_to(:log_fatal).with(1).arguments }
  end

  describe "#logger" do
    subject(:logger) { LoggingClass.new.logger }

    it { is_expected.to eq(SidekiqUniqueJobs::Script.logger) }
  end

  describe ".logger" do
    subject(:logger) { LoggingClass.logger }

    it { is_expected.to eq(SidekiqUniqueJobs::Script.logger) }
  end

  shared_examples "delegates to logger" do |level:|
    subject(:logging) { LoggingClass.new }

    let(:logger)  { logging.logger }
    let(:message) { "I am a message" }

    before do
      allow(logger).to receive(level).and_return("ROCK n ROLL")
    end

    it "delegates to logger" do
      expect(logging.send("log_#{level}".to_sym, message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  it_behaves_like "delegates to logger", level: :debug
  it_behaves_like "delegates to logger", level: :info
  it_behaves_like "delegates to logger", level: :warn
  it_behaves_like "delegates to logger", level: :error
  it_behaves_like "delegates to logger", level: :fatal
end
