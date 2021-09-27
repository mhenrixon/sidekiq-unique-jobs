# frozen_string_literal: true

RSpec.describe "Sidekiq::Api" do
  let(:item) do
    { "class" => "JustAWorker",
      "queue" => "testqueue",
      "args" => [{ foo: "bar" }] }
  end
  let(:lock_digest) { "uniquejobs:577db3c4fc72230bf2c256faa708a083" }
  let(:key)         { SidekiqUniqueJobs::Key.new(lock_digest) }

  describe Sidekiq::SortedEntry::UniqueExtension do
    it "deletes uniqueness lock on delete" do
      expect(JustAWorker.perform_in(60 * 60 * 3, foo: "bar")).to be_truthy
      expect(unique_keys).not_to match_array([])

      Sidekiq::ScheduledSet.new.each(&:delete)
      expect(unique_keys).to match_array([])

      expect(JustAWorker.perform_in(60 * 60 * 3, boo: "far")).to be_truthy
    end

    it "deletes uniqueness lock on remove_job" do
      expect(JustAWorker.perform_in(60 * 60 * 3, foo: "bar")).to be_truthy
      expect(unique_keys).not_to match_array([])

      Sidekiq::ScheduledSet.new.each do |entry|
        entry.send(:remove_job) do |message|
          item = Sidekiq.load_json(message)
          expect(item).to match(
            hash_including(
              "args" => [{ "foo" => "bar" }],
              "class" => "JustAWorker",
              "jid" => kind_of(String),
              "lock_ttl" => nil,
              "lock_timeout" => 0,
              "queue" => "testqueue",
              "retry" => true,
              "lock" => "until_executed",
              "lock_args" => [{ "foo" => "bar" }],
              "lock_digest" => key.digest,
              "lock_prefix" => "uniquejobs",
            ),
          )
        end
      end
      expect(unique_keys).to match_array([])
      expect(JustAWorker.perform_in(60 * 60 * 3, boo: "far")).to be_truthy
    end
  end

  if Sidekiq.const_defined?("JobRecord")
    describe Sidekiq::JobRecord::UniqueExtension do
      it "deletes uniqueness lock on delete" do
        jid = JustAWorker.perform_async(roo: "baf")
        expect(unique_keys).not_to match_array([])
        Sidekiq::Queue.new("testqueue").find_job(jid).delete
        expect(unique_keys).to match_array([])
      end
    end
  else
    describe Sidekiq::Job::UniqueExtension do
      it "deletes uniqueness lock on delete" do
        jid = JustAWorker.perform_async(roo: "baf")
        expect(unique_keys).not_to match_array([])
        Sidekiq::Queue.new("testqueue").find_job(jid).delete
        expect(unique_keys).to match_array([])
      end
    end
  end

  describe Sidekiq::Queue::UniqueExtension do
    it "deletes uniqueness locks on clear" do
      JustAWorker.perform_async(oob: "far")
      expect(unique_keys).not_to match_array([])
      Sidekiq::Queue.new("testqueue").clear
      expect(unique_keys).to match_array([])
    end
  end

  describe Sidekiq::JobSet::UniqueExtension do
    it "deletes uniqueness locks on clear" do
      JustAWorker.perform_in(60 * 60 * 3, roo: "fab")
      expect(unique_keys).not_to match_array([])
      Sidekiq::JobSet.new("schedule").clear
      expect(unique_keys).to match_array([])
    end
  end

  describe Sidekiq::ScheduledSet::UniqueExtension do
    it "deletes uniqueness locks on clear" do
      JustAWorker.perform_in(60 * 60 * 3, roo: "fab")
      expect(unique_keys).not_to match_array([])
      Sidekiq::ScheduledSet.new.clear
      expect(unique_keys).to match_array([])
    end

    it "deletes uniqueness locks on delete_by_score" do
      JustAWorker.perform_in(60 * 60 * 3, roo: "fab")
      expect(unique_keys).not_to match_array([])
      scheduled_set = Sidekiq::ScheduledSet.new
      scheduled_set.each do |job|
        scheduled_set.delete(job.score, job.jid)
      end

      expect(unique_keys).to match_array([])
    end
  end
end
