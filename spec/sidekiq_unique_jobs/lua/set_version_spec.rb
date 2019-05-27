# frozen_string_literal: true

require "spec_helper"
RSpec.describe "set_version.lua" do
  subject(:set_version) { call_script(:set_version, keys, argv) }

  let(:keys)        { [live_key, dead_key] }
  let(:argv)        { [new_version] }
  let(:now_f)       { SidekiqUniqueJobs.now_f }
  let(:live_key)    { SidekiqUniqueJobs::LIVE_VERSION }
  let(:dead_key)    { SidekiqUniqueJobs::DEAD_VERSION }
  let(:new_version) { "1.2.3" }
  let(:old_version) { nil }

  context "without previous version" do
    it "updates Redis correctly" do
      expect { set_version }.to change { get(live_key) }.to(new_version)
      expect(get(dead_key)).to eq(nil)
      expect(set_version).to eq(1)
    end
  end

  context "with previous version" do
    before { set(live_key, old_version) }

    context "when different from current version" do
      let(:old_version) { "1.1.1" }

      it "updates Redis correctly" do
        expect { set_version }.to change { get(live_key) }.from(old_version).to(new_version)
        expect(get(dead_key)).to eq(old_version)
        expect(set_version).to eq(1)
      end
    end

    context "when matching current version" do
      let(:old_version) { new_version }

      it "updates Redis correctly" do
        expect { set_version }.not_to change { get(live_key) }.from(new_version)
        expect(get(dead_key)).to eq(nil)
        expect(set_version).to eq(nil)
      end
    end
  end
end
