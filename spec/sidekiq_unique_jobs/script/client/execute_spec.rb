# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Script::Client, "#execute" do
  subject(:execute) { client.execute(script_name, redis, **arguments) }

  include_context "with test config"

  let(:client)              { described_class.new(config) }
  let(:script_name)         { :test }
  let(:redis)               { instance_spy(RedisClient) }
  let(:arguments)           { { keys: keys, argv: argv } }
  let(:keys)                { %w[key_one key_two key_tre key_for key_fav] }
  let(:argv)                { %w[arg_one arg_two arg_tre arg_for arg_fav] }
  let(:exception)           { nil }
  let(:redis_error_message) { nil }
  let(:script)              { SidekiqUniqueJobs::Script::Script.new(name: script_name, root_path: SCRIPTS_PATH) }
  let(:scripts)             { instance_spy(SidekiqUniqueJobs::Script::Scripts) }

  let(:script_source) do
    <<~LUA
      local key_one = KEYS[1]
      local key_two = KEYS[2]
      local key_tre = KEYS[3]
      local key_for = KEYS[4]
      local key_fiv = KEYS[5]
      local arg_one = ARGV[1]
      local arg_two = ARGV[2]
      local arg_tre = ARGV[3]
      local arg_for = ARGV[4]
      local arg_fiv = ARGV[5]
    LUA
  end

  context "when error is raised" do
    before do
      allow(SidekiqUniqueJobs::Script::Scripts).to receive(:fetch).with(config.scripts_path).and_return(scripts)
      allow(scripts).to receive_messages(delete: true, kill: true, load: true, fetch: script)

      allow(client.logger).to receive_messages(warn: true, debug: true)

      call_count = 0
      allow(scripts).to receive(:execute) do
        call_count += 1
        call_count.odd? ? raise(RedisClient::CommandError, redis_error_message) : "bogus"
      end

      exception
    end

    context "when message starts with ERR" do
      let(:redis_error_message) do
        <<~ERR
          ERR Error running script (execute to f_178d75adaa46af3d8237cfd067c9fdff7b9d504f): [string "func definition"]:7: attempt to compare nil with number
        ERR
      end

      let(:error_message) do
        <<~ERR_MSG
          attempt to compare nil with number

              5: local key_fiv = KEYS[5]
              6: local arg_one = ARGV[1]
           => 7: local arg_two = ARGV[2]
              8: local arg_tre = ARGV[3]
              9: local arg_for = ARGV[4]

        ERR_MSG
      end

      let(:exception) do
        execute
      rescue SidekiqUniqueJobs::Script::LuaError => ex
        ex
      end

      specify do
        expect(exception.message).to eq(error_message)
        expect(exception.backtrace.first).to match(%r{spec/support/lua/test.lua:7})
        expect(exception.backtrace[1]).to match(/client.rb/)

        expect(scripts).not_to have_received(:delete)
        expect(scripts).to have_received(:execute).with(script_name, redis, keys: keys, argv: argv).once
      end
    end

    context "when message starts with BUSY" do
      let(:redis_error_message) do
        "BUSY Redis is busy running a script. " \
          "You can only execute SCRIPT KILL or SHUTDOWN NOSAVE."
      end

      context "when .script(:kill) raises CommandError" do
        before do
          allow(scripts).to receive(:kill).and_raise(RedisClient::CommandError, "NOT BUSY")
          allow(client.logger).to receive(:warn)
        end

        specify do
          expect { execute }.not_to raise_error
          expect(client.logger).to have_received(:warn).with(kind_of(RedisClient::CommandError))
          expect(scripts).to have_received(:execute).with(script_name, redis, keys: keys, argv: argv).twice
        end
      end

      context "when .script(:kill) is successful" do
        before do
          allow(scripts).to receive(:kill).and_return(true)
        end

        specify do
          expect { execute }.not_to raise_error

          expect(scripts).to have_received(:kill).with(redis)
          expect(scripts).to have_received(:execute).with(script_name, redis, keys: keys, argv: argv).twice
        end
      end
    end

    context "when message starts with NOSCRIPT" do
      let(:redis_error_message) { "NOSCRIPT No matching script. Please use EVAL." }

      specify do
        expect { execute }.not_to raise_error

        expect(scripts).to have_received(:delete).with(script_name)
        expect(scripts).to have_received(:execute).with(script_name, redis, keys: keys, argv: argv).twice
      end
    end
  end
end
