# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::UpdateVersion do
  describe ".call" do
    subject(:call) { described_class.call }

    let(:live_key)    { SidekiqUniqueJobs::LIVE_VERSION }
    let(:dead_key)    { SidekiqUniqueJobs::DEAD_VERSION }
    let(:new_version) { "1.2.3" }
    let(:old_version) { nil }

    before do
      allow(SidekiqUniqueJobs).to receive(:version).and_return(new_version)
    end

    context "without previous version" do
      it "updates Redis correctly" do
        expect { call }.to change { get(live_key) }.to(new_version)
        expect(get(dead_key)).to be_nil
      end
    end

    context "with previous version" do
      before { set(live_key, old_version) }

      context "when different from current version" do
        let(:old_version) { "1.1.1" }

        it "updates Redis correctly" do
          expect { call }.to change { get(live_key) }.from(old_version).to(new_version)
          expect(get(dead_key)).to eq(old_version)
        end
      end

      context "when matching current version" do
        let(:old_version) { new_version }

        it "updates Redis correctly" do
          expect { call }.not_to change { get(live_key) }.from(new_version)
          expect(get(dead_key)).to be_nil
        end
      end
    end
  end
end
