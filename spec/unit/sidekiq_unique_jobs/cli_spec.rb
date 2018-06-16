# frozen_string_literal: true

require 'spec_helper'
require 'thor/runner'
require 'irb'

RSpec.describe SidekiqUniqueJobs::Cli, redis: :redis, ruby_ver: '>= 2.4' do
  let(:item) do
    {
      'jid'           => jid,
      'unique_digest' => unique_key,
    }
  end
  let(:jid)           { 'abcdefab' }
  let(:unique_key)    { 'uniquejobs:abcdefab' }
  let(:max_lock_time) { 1 }
  let(:pattern)       { '*' }

  describe '#help' do
    let(:output) { capture(:stdout) { described_class.start(%w[help]) } }
    let(:banner) do
      <<~HEADER
        Commands:
          jobs  console         # drop into a console with easy access to helper methods
          jobs  del PATTERN     # deletes unique keys from redis by pattern
          jobs  help [COMMAND]  # Describe available commands or one specific command
          jobs  keys PATTERN    # list all unique keys and their expiry time
      HEADER
    end

    it 'displays help' do
      expect(output).to include(banner)
    end

    describe '#help del' do
      let(:output) { capture(:stdout) { described_class.start(%w[help del]) } }
      let(:banner) do
        <<~HEADER
          Usage:
            jobs  del PATTERN

          Options:
            d, [--dry-run], [--no-dry-run]  # set to false to perform deletion
            c, [--count=N]                  # The max number of keys to return
                                            # Default: 1000

          deletes unique keys from redis by pattern
        HEADER
      end

      it 'displays help about the `del` command' do
        expect(output).to eq(banner)
      end
    end

    describe '#help keys' do
      let(:output) { capture(:stdout) { described_class.start(%w[help keys]) } }
      let(:banner) do
        <<~HEADER
          Usage:
            jobs  keys PATTERN

          Options:
            c, [--count=N]  # The max number of keys to return
                            # Default: 1000

          list all unique keys and their expiry time
        HEADER
      end

      it 'displays help about the `key` command' do
        expect(output).to eq(banner)
      end
    end
  end

  describe '.keys' do
    let(:output) { capture(:stdout) { described_class.start(%w[keys * --count 1000]) } }

    context 'when no keys exist' do
      let(:expected) { "Found 0 keys matching '#{pattern}':\n" }

      specify { expect(output).to eq(expected) }
    end

    context 'when a key exists' do
      before do
        SidekiqUniqueJobs::Locksmith.new(item).lock
      end

      after { SidekiqUniqueJobs::Util.del('*', 1000, false) }

      specify do
        expect(output).to include("Found 3 keys matching '*':")
        expect(output).to include('uniquejobs:abcdefab:EXISTS')
        expect(output).to include('uniquejobs:abcdefab:GRABBED')
        expect(output).to include('uniquejobs:abcdefab:GRABBED')
      end
    end
  end

  describe '.del' do
    let(:expected) do
      <<~HEADER
        Deleted 3 keys matching '*'
      HEADER
    end

    before do
      SidekiqUniqueJobs::Locksmith.new(item).lock
    end

    specify do
      output = capture(:stdout) { described_class.start(%w[del * --no-dry-run --count 1000]) }
      expect(output).to eq(expected)
      expect(SidekiqUniqueJobs::Util.keys).to eq([])
    end
  end

  describe '.console', ruby_ver: '>= 2.5.1' do
    let(:expected) do
      <<~HEADER
        Use `keys '*', 1000 to display the first 1000 unique keys matching '*'
        Use `del '*', 1000, true (default) to see how many keys would be deleted for the pattern '*'
        Use `del '*', 1000, false to delete the first 1000 keys matching '*'
      HEADER
    end
    let(:output) { capture(:stdout) { described_class.start(%w[console]) } }

    specify do
      expect(Object).to receive(:include).with(SidekiqUniqueJobs::Util).and_return(true)
      allow(Pry).to receive(:start).and_return(true)
      expect(output).to eq(expected)
    end
  end
end
