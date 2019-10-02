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
  let(:fake_pry) do
    stub_const(
      "Pry",
      Class.new do
        def self.start; end
      end,
    )
  end
  let(:fake_irb) do
    stub_const(
      "IRB",
      Class.new do
        def self.start; end
      end,
    )
  end

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

  describe ".console" do
    subject(:console) { capture(:stdout) { exec(:console) } }

    before do
      allow(console_class).to receive(:start)
    end

    shared_examples "start console" do
      specify do
        expect(console).to include <<~HEADER
          Use `keys '*', 1000 to display the first 1000 unique keys matching '*'
          Use `del '*', 1000, true (default) to see how many keys would be deleted for the pattern '*'
          Use `del '*', 1000, false to delete the first 1000 keys matching '*'
        HEADER
      end
    end

    context "when Pry is available" do
      let(:console_class) { fake_pry }

      it_behaves_like "start console"
    end

    context "when Pry is unavailable" do
      let(:console_class) { fake_irb }

      before { hide_const("Pry") }

      it_behaves_like "start console"
    end
  end
end
