# frozen_string_literal: true

require "thor/runner"
require "irb"

RSpec.describe SidekiqUniqueJobs::Cli, redis: :redis, ruby_ver: ">= 2.4" do
  let(:item) do
    {
      "jid" => jid,
      "unique_digest" => unique_key,
    }
  end
  let(:jid)           { "abcdefab" }
  let(:unique_key)    { "uniquejobs:abcdefab" }
  let(:max_lock_time) { 1 }
  let(:pattern)       { "*" }

  def exec(*cmds)
    described_class.start(cmds)
  end

  describe "#help" do
    subject(:help) { capture(:stdout) { exec(:help) } }

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
      subject(:help) { capture(:stdout) { exec(:help, :del) } }

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
      subject(:help) { capture(:stdout) { exec(:help, :keys) } }

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
    subject(:keys) { capture(:stdout) { exec("keys", "*", "--count", "1000") } }

    context "when no keys exist" do
      it { is_expected.to eq("Found 0 keys matching '#{pattern}':\n") }
    end

    context "when a key exists" do
      before do
        SidekiqUniqueJobs::Locksmith.new(item).lock
      end

      after { SidekiqUniqueJobs::Util.del("*", 1000) }

      it { is_expected.to include("Found 2 keys matching '*':") }
      it { is_expected.to include("uniquejobs:abcdefab:EXISTS") }
      it { is_expected.to include("uniquejobs:abcdefab:GRABBED") }
    end
  end

  describe ".console", ruby_ver: ">= 2.6.5" do
    subject(:console) { capture(:stdout) { exec(:console) } }

    let(:header) do
      <<~HEADER
        Use `keys '*', 1000 to display the first 1000 unique keys matching '*'
        Use `del '*', 1000, true (default) to see how many keys would be deleted for the pattern '*'
        Use `del '*', 1000, false to delete the first 1000 keys matching '*'
      HEADER
    end

    before do
      allow(self).to receive(:require).with("pry").and_return(true)
      allow(console_class).to receive(:start).and_return(true)
    end

    def stub_console(const)
      stub_const(const, Class.new { def self.start; end })
    end

    context "when Pry is available" do
      let(:console_class) { stub_console("Pry") }

      it { is_expected.to include(header) }
    end

    context "when Pry is unavailable" do
      let(:console_class) { stub_console("IRB") }

      it { is_expected.to include(header) }
    end
  end
end
