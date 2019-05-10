# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Logging do
  let(:logger)  { SidekiqUniqueJobs.logger }
  let(:message) { "A log message" }
  let(:level)   { nil }

  before do
    allow(logger).to receive(level)
  end

  include described_class

  describe "#log_debug" do
    let(:level) { :debug }

    it "delegates to logger.debug" do
      expect(log_debug(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_info" do
    let(:level) { :info }

    it "delegates to logger.info" do
      expect(log_info(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_warn" do
    let(:level) { :warn }

    it "delegates to logger.warn" do
      expect(log_warn(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_error" do
    let(:level) { :error }

    it "delegates to logger.error" do
      expect(log_error(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_fatal" do
    let(:level) { :fatal }

    it "delegates to logger.fatal" do
      expect(log_fatal(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end
end
