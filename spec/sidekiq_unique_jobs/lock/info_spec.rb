# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Lock::Info do
  subject(:entity) { described_class.new(key) }

  let(:key)    { SidekiqUniqueJobs::Key.new(digest) }
  let(:digest) { "digest:#{SecureRandom.hex(12)}" }

  describe "#value" do
    subject(:value) { entity.value }

    context "with redis data" do
      before { entity.set(key: "val") }

      it { is_expected.to eq("key" => "val") }
    end

    context "without redis data" do
      it { is_expected.to eq(nil) }
    end
  end

  describe "#none?" do
    subject(:none?) { entity.none? }

    context "with redis data" do
      before { entity.set(key: "val") }

      it { is_expected.to eq(false) }
    end

    context "without redis data" do
      it { is_expected.to eq(true) }
    end
  end

  describe "#present?" do
    subject(:present?) { entity.present? }

    context "with redis data" do
      before { entity.set(key: "val") }

      it { is_expected.to eq(true) }
    end

    context "without redis data" do
      it { is_expected.to eq(false) }
    end
  end

  describe "#[]" do
    subject(:result) { entity["key"] }

    context "with redis data" do
      before { entity.set(key: "val") }

      it { is_expected.to eq("val") }
    end

    context "without redis data" do
      it { is_expected.to eq(nil) }
    end
  end

  describe "#set" do
    subject(:set) { entity.set(obj) }

    let(:obj) { nil }

    context "when SidekiqUniqueJobs.config.lock_info = false" do
      around do |example|
        SidekiqUniqueJobs.use_config(lock_info: false) do
          example.run
        end
      end

      it { is_expected.to eq(nil) }
    end

    context "when not given a Hash" do
      it { expect { set }.to raise_error(SidekiqUniqueJobs::InvalidArgument, "argument `obj` () needs to be a hash") }
    end

    context "when given a Hash" do
      let(:obj) { { key: "val" } }

      it { is_expected.to eq("key" => "val") }
    end
  end
end
