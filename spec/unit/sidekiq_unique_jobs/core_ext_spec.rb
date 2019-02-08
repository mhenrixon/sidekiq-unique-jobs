# frozen_string_literal: true

require "spec_helper"
RSpec.describe "core_ext.rb" do
  describe Hash do
    let(:hash) { { test: :me, not: :me } }

    describe "#slice" do
      specify { expect(hash.slice(:test)).to eq(test: :me) }
    end

    describe "#slice!" do
      specify { expect { hash.slice!(:test) }.to change { hash }.to(test: :me) }
    end

    describe "#stringify_keys" do
      subject(:stringify_keys) { hash.stringify_keys }

      it { is_expected.to eq("test" => :me, "not" => :me) }
    end

    describe "#transform_keys" do
      subject(:transform_keys) { hash.transform_keys(&:to_s) }

      it { is_expected.to eq("test" => :me, "not" => :me) }
    end
  end

  describe Array do
    let(:array)         { [1, 2, nil, last_argument] }
    let(:last_argument) { Object.new }

    describe "#extract_options!" do
      subject(:extract_options!) { array.extract_options! }

      context "when last argument is a hash" do
        let(:last_argument) { { test: :me, not: :me } }

        it { is_expected.to eq(last_argument) }
      end

      context "when last argument is not a hash" do
        let(:last_argument) { nil }

        it { is_expected.to eq({}) }
      end
    end
  end
end
