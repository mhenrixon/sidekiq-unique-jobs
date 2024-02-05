# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Script::Scripts do
  let(:scripts) { described_class.new(scripts_path) }

  let(:redis)        { Sidekiq.redis { |conn| return conn } }
  let(:script_name)  { :test }
  let(:script_path)  { SCRIPTS_PATH.join("#{script_name}.lua").to_s }
  let(:script_sha)   { "63af434656e22ce2cd7f2d3b2e937d3e249cb309" }
  let(:scripts_path) { SCRIPTS_PATH }

  describe "#fetch" do
    subject(:fetch) { scripts.fetch(script_name, redis) }

    context "when script was loaded" do
      before do
        scripts.load(script_name, redis)
      end

      it "loads script to redis" do
        expect { fetch }.not_to change { scripts.count }.from(1)
      end

      its(:name) { is_expected.to eq(script_name) }
      its(:path) { is_expected.to eq(script_path) }
      its(:sha)  { is_expected.to eq(script_sha) }
    end

    context "when script wasn't loaded" do
      it "loads script to redis" do
        expect { fetch }.to change { scripts.count }.by(1)
      end

      its(:name) { is_expected.to eq(script_name) }
      its(:path) { is_expected.to eq(script_path) }
      its(:sha)  { is_expected.to eq(script_sha) }
    end
  end

  describe "#execute" do
    subject(:execute) { scripts.execute(script_name, redis, **arguments) }

    let(:keys)      { %w[key_one key_two key_tre key_for key_fav] }
    let(:argv)      { %w[arg_one arg_two arg_tre arg_for arg_fav] }
    let(:arguments) { { keys: keys, argv: argv } }

    it { is_expected.to eq("arg_for") }
  end

  describe "#load" do
    subject(:load) { scripts.load(script_name, redis) }

    its(:class) { is_expected.to eq(SidekiqUniqueJobs::Script::Script) }
    its(:name)  { is_expected.to eq(script_name) }
    its(:path)  { is_expected.to eq(script_path) }
    its(:sha)   { is_expected.to eq(script_sha) }
  end

  describe "#kill" do
    subject(:kill) { scripts.kill(redis) }

    specify { expect { kill }.to raise_error(RedisClient::CommandError, "NOTBUSY No scripts in execution right now.") }
  end
end
