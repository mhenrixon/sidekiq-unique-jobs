# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Script::Config do
  let(:config)       { described_class.new }

  let(:script_name)  { :test }
  let(:scripts_path) { SCRIPTS_PATH }

  it { is_expected.to respond_to(:logger).with(0).arguments }
  it { is_expected.to respond_to(:logger=).with(1).arguments }
  it { is_expected.to respond_to(:scripts_path).with(0).arguments }
  it { is_expected.to respond_to(:scripts_path=).with(1).arguments }

  describe "scripts_path=" do
    subject(:set_scripts_path) { config.scripts_path = new_path }

    context "when given a Pathname" do
      let(:new_path) { SCRIPTS_PATH }

      it { expect { set_scripts_path }.to change { config.scripts_path }.from(nil).to(new_path) }
    end

    context "when given a String" do
      let(:new_path) { SCRIPTS_PATH.to_s }

      it { expect { set_scripts_path }.to change { config.scripts_path }.from(nil).to(Pathname.new(new_path)) }
    end

    context "when given a Class" do
      let(:new_path) { Object.new }

      it { expect { set_scripts_path }.to raise_error(ArgumentError, "#{new_path} should be a Pathname or String") }
    end

    context "when directory does not exist" do
      let(:new_path) { SCRIPTS_PATH.join("non-existing", "path") }

      it do
        expect { set_scripts_path }.to raise_error(ArgumentError, "#{new_path} does not exist")
      end
    end
  end

  describe "logger=" do
    subject(:set_logger) { config.logger = logger }

    context "when logger is a Logger" do
      let(:logger) { Logger.new($stdout) }

      it { expect { set_logger }.to change { config.logger }.to(logger) }
    end

    context "when logger isn't a Logger" do
      let(:logger) { Object.new }

      it { expect { set_logger }.to raise_error(ArgumentError, "#{logger} should be a Logger") }
    end
  end
end
