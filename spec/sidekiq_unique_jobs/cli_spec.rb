# frozen_string_literal: true

require "thor/runner"
require "irb"

RSpec.describe SidekiqUniqueJobs::Cli, ruby_ver: ">= 2.4" do
  let(:item) do
    {
      "jid" => jid,
      "unique_digest" => digest,
    }
  end
  let(:jid)           { "abcdefab" }
  let(:digest)        { "uniquejobs:abcdefab" }
  let(:max_lock_time) { 1 }
  let(:pattern)       { "*" }

  describe "#help" do
    subject(:help) { capture(:stdout) { described_class.start(%w[help]) } }

    it "displays help" do
      expect(help).to include <<~HEADER
        Commands:
          jobs  console         # drop into a console with easy access to helper methods
          jobs  del PATTERN     # deletes unique keys from redis by pattern
          jobs  help [COMMAND]  # Describe available commands or one specific command
          jobs  keys PATTERN    # list all unique keys and their expiry time
      HEADER
    end

    describe "#help del" do
      subject(:help) { capture(:stdout) { described_class.start(%w[help del]) } }

      it "displays help about the `del` command" do
        expect(help).to eq <<~HEADER
          Usage:
            jobs  del PATTERN

          Options:
            d, [--dry-run], [--no-dry-run]  # set to false to perform deletion
            c, [--count=N]                  # The max number of keys to return
                                            # Default: 1000

          deletes unique keys from redis by pattern
        HEADER
      end
    end

    describe "#help keys" do
      subject(:help) { capture(:stdout) { described_class.start(%w[help keys]) } }

      it "displays help about the `key` command" do
        expect(help).to eq <<~HEADER
          Usage:
            jobs  keys PATTERN

          Options:
            c, [--count=N]  # The max number of keys to return
                            # Default: 1000

          list all unique keys and their expiry time
        HEADER
      end
    end
  end

  describe ".keys" do
    subject(:keys) { capture(:stdout) { described_class.start(%w[keys * --count 1000]) } }

    context "when no keys exist" do
      it { is_expected.to eq("Found 0 keys matching '#{pattern}':\n") }
    end

    context "when a key exists" do
      before { set(digest, jid) }

      after { SidekiqUniqueJobs::Util.del("*", 1000) }

      it { is_expected.to include("Found 1 keys matching '*':") }
      it { is_expected.to include("uniquejobs:abcdefab") }
    end
  end

  describe ".del" do
    subject(:del) { capture(:stdout) { described_class.start(args) } }

    let(:args) { %W[del * #{options} --count 1000] }

    before { set(digest, jid) }

    context "with argument --dry-run" do
      let(:options) { "--dry-run" }

      specify do
        expect(del).to eq("Would delete 1 keys matching '*'\n")
        expect(SidekiqUniqueJobs::Util.keys).not_to eq([])
      end
    end

    context "with argument --no-dry-run" do
      let(:options) { "--no-dry-run" }

      specify do
        expect(del).to eq("Deleted 1 keys matching '*'\n")
        expect(SidekiqUniqueJobs::Util.keys).to eq([])
      end
    end
  end

  describe ".console" do
    subject(:console) { capture(:stdout) { described_class.start(%w[console]) } }

    shared_examples "start console" do
      specify do
        allow(Object).to receive(:include)
        allow(console_class).to receive(:start).and_return(true)
        expect(console).to eq <<~HEADER
          Use `keys '*', 1000 to display the first 1000 unique keys matching '*'
          Use `del '*', 1000, true (default) to see how many keys would be deleted for the pattern '*'
          Use `del '*', 1000, false to delete the first 1000 keys matching '*'
        HEADER

        expect(Object).to have_received(:include).with(SidekiqUniqueJobs::Util)
      end
    end

    context "when Pry is available" do
      let(:console_class) { defined?(Pry) ? Pry : IRB }

      before do
        begin
          require "pry"
        rescue NameError, LoadError, NoMethodError # rubocop:disable Lint/ShadowedException
          p "Pry not available, falling back to IRB"
        end
      end

      it_behaves_like "start console"
    end

    context "when Pry is unavailable" do
      let(:console_class) { IRB }

      before { hide_const("Pry") }

      it_behaves_like "start console"
    end
  end
end
