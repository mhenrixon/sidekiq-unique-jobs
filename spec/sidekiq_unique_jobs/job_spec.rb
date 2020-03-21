# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Job do
  let(:job) do
    { "class" => worker_class,
      "queue" => queue,
      "args" => args }
  end
  let(:worker_class) { MyUniqueJob }
  let(:queue)        { "anotherqueue" }
  let(:args)         { [1, 2] }

  describe ".prepare" do
    subject(:prepare) { described_class.prepare(job) }

    it "adds required hash data" do
      expect(prepare).to eq(
        {
          "class" => worker_class,
          "queue" => queue,
          "args" => [1, 2],
          "lock_timeout" => MyUniqueJob.get_sidekiq_options["lock_timeout"].to_i,
          "lock_ttl" => MyUniqueJob.get_sidekiq_options["lock_ttl"],
          "unique_args" => args,
          "unique_digest" => "uniquejobs:77b7db49e1339ec4bda2addf1e74aae0",
          "unique_prefix" => "uniquejobs",
        },
      )
    end
  end
end
