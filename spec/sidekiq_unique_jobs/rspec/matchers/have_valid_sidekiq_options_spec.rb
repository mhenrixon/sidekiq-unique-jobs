# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::RSpec::Matchers::HaveValidSidekiqOptions do
  describe "#matches?" do
    if Sidekiq.const_defined?("JobRecord")
      context "when sidekiq options are valid" do
        it { expect(AnotherUniqueJob).to have_valid_sidekiq_options }
      end

      context "when sidekiq options lacks `:lock`" do
        it "raises SidekiqUniqueJobs::NotUniqueWorker" do
          AnotherUniqueJob.use_options({}) do
            AnotherUniqueJob.sidekiq_options_hash.delete("lock")
            expect { expect(AnotherUniqueJob).to have_valid_sidekiq_options }
              .to raise_error(SidekiqUniqueJobs::NotUniqueWorker)
          end
        end
      end

      context "when sidekiq options are invalid" do
        it "raises SidekiqUniqueJobs::NotUniqueWorker" do
          AnotherUniqueJob.use_options(on_client_conflict: :reject, on_server_conflict: :replace) do
            expect(AnotherUniqueJob).not_to have_valid_sidekiq_options
          end
        end
      end
    end

    context "when sidekiq options are valid" do
      it { expect(AnotherUniqueJob).to have_valid_sidekiq_options }
    end

    context "when sidekiq options lacks `:lock`" do
      it "raises SidekiqUniqueJobs::NotUniqueWorker" do
        AnotherUniqueJob.use_options({}) do
          AnotherUniqueJob.sidekiq_options_hash.delete("lock")
          expect { expect(AnotherUniqueJob).to have_valid_sidekiq_options }
            .to raise_error(SidekiqUniqueJobs::NotUniqueWorker)
        end
      end
    end

    context "when sidekiq options are invalid" do
      it "raises SidekiqUniqueJobs::NotUniqueWorker" do
        AnotherUniqueJob.use_options(on_client_conflict: :reject, on_server_conflict: :replace) do
          expect(AnotherUniqueJob).not_to have_valid_sidekiq_options
        end
      end
    end
  end
end
