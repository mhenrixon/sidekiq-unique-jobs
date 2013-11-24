require 'spec_helper'
require 'sidekiq/worker'
require "sidekiq-unique-jobs"
require 'sidekiq/scheduled'
require 'sidekiq-unique-jobs/middleware/server/unique_jobs'

describe "When Sidekiq::Testing is enabled" do
  describe 'when set to :fake!', sidekiq: :fake do
    context "with unique worker" do
      it "does not push duplicate messages" do
        param = 'work'
        expect(UniqueWorker).to have_enqueued_jobs(0)
        UniqueWorker.perform_async(param)
        expect(UniqueWorker).to have_enqueued_jobs(1)
        expect(UniqueWorker).to have_enqueued_job(param)
        UniqueWorker.perform_async(param)
        expect(UniqueWorker).to have_enqueued_jobs(1)
      end
    end

    context "with non-unique worker" do

      it "pushes duplicates messages" do
        param = 'work'
        expect(MyWorker).to have_enqueued_jobs(0)
        MyWorker.perform_async(param)
        expect(MyWorker).to have_enqueued_jobs(1)
        expect(MyWorker).to have_enqueued_job(param)
        MyWorker.perform_async(param)
        expect(MyWorker).to have_enqueued_jobs(2)
      end
    end
  end
end
