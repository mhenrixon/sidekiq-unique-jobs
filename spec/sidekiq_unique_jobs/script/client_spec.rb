# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Script::Client do
  let(:client) { described_class.new(config) }

  include_context "with test config"

  describe ".execute" do
    subject(:execute) { client.execute(script_name, redis, **arguments) }

    let(:keys)         { %w[key_one key_two key_tre key_for key_fav] }
    let(:argv)         { %w[arg_one arg_two arg_tre arg_for arg_fav] }
    let(:redis)        { Sidekiq.redis { |conn| return conn } }
    let(:scriptsha)    { "abcdefab" }
    let(:arguments)    { { keys: keys, argv: argv } }
    let(:script_name)  { :test }

    before do
      allow(client.logger).to receive(:debug).and_return(true)
    end

    it { is_expected.to eq("arg_for") }
  end
end
