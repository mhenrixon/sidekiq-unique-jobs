# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Fetch::StartupCleanup do
  let(:digest) { "uniquejobs:startup-test-digest" }
  let(:jid) { "startup-test-jid" }
  let(:lock) { SidekiqUniqueJobs::Lock.new(digest) }
  let(:lock_info) { { type: :until_executed } }

  before do
    flush_redis
  end

  describe ".call" do
    context "when lock_aware_fetch is disabled" do
      it "does not run cleanup" do
        lock.lock(jid, lock_info)

        SidekiqUniqueJobs.use_config(lock_aware_fetch: false) do
          described_class.call
        end

        expect(lock.locked_jids).to include(jid)
      end
    end

    context "when lock_aware_fetch is enabled" do
      context "when lock has no active process" do
        it "cleans up the orphaned lock" do
          lock.lock(jid, lock_info)

          SidekiqUniqueJobs.use_config(lock_aware_fetch: true) do
            described_class.call
          end

          expect(lock.locked_jids).not_to include(jid)
        end
      end

      context "when there are no locks" do
        it "completes without error" do
          SidekiqUniqueJobs.use_config(lock_aware_fetch: true) do
            expect { described_class.call }.not_to raise_error
          end
        end
      end
    end
  end
end
