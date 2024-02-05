# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Script::LuaError do
  let(:client) { described_class.new(config) }

  describe ".intercepts?" do
    subject(:intercepts?) { described_class.intercepts?(error) }

    context "when error contains ERR Error running script" do
      let(:error)   { RedisClient::CommandError.new(message) }
      let(:message) do
        'ERR Error running script (execute to f_178d75adaa46af3d8237cfd067c9fdff7b9d504f): ' \
          '[string "func definition"]:7: attempt to compare nil with number'
      end

      it { is_expected.to be(true) }
    end

    context "when error contains ERR Error compiling script" do
      let(:error)   { RedisClient::CommandError.new(message) }
      let(:message) do
        'ERR Error compiling script (execute to f_178d75adaa46af3d8237cfd067c9fdff7b9d504f): ' \
          '[string "func definition"]:7: attempt to compare nil with number'
      end

      it { is_expected.to be(true) }
    end
  end
end
