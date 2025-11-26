# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Job do
  let(:job) do
    { "class" => job_class,
      "queue" => queue,
      "args" => args }
  end
  let(:job_class) { MyUniqueJob }
  let(:queue)     { "anotherqueue" }
  let(:args)      { [1, 2] }

  describe ".prepare" do
    subject(:prepare) { described_class.prepare(job) }

    it "adds required hash data" do
      expect(prepare).to eq(
        {
          "class" => job_class,
          "queue" => queue,
          "args" => [1, 2],
          "lock_timeout" => MyUniqueJob.get_sidekiq_options["lock_timeout"].to_i,
          "lock_ttl" => MyUniqueJob.get_sidekiq_options["lock_ttl"],
          "lock_args" => args,
          "lock" => :until_executed,
          "lock_digest" => "uniquejobs:6b6835a019cad7c2a7a4e53e20a9184c",
          "lock_prefix" => "uniquejobs",
        },
      )
    end

    context "when there is a hash in on_conflict" do
      let(:job_class) { UniqueJobOnConflictHash }

      let(:job) { job_class.get_sidekiq_options }

      it "stringifies the on_conflict hash" do
        expect(prepare).to match(
          hash_including(
            "on_conflict" => {
              "client" => :log,
              "server" => :reschedule,
            },
          ),
        )
      end
    end

    context "when lock_prefix is set" do
      let(:job) do
        super().merge("lock_prefix" => "custom_prefix")
      end

      it "uses the custom lock_prefix" do
        expect(prepare).to match(
          hash_including(
            "lock_prefix" => "custom_prefix",
            "lock_digest" => "custom_prefix:6b6835a019cad7c2a7a4e53e20a9184c",
          ),
        )
      end
    end
  end
end
