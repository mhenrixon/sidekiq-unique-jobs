require 'spec_helper'
require 'sidekiq/worker'
require "sidekiq-unique-jobs"
require 'sidekiq/scheduled'
require 'sidekiq-unique-jobs/middleware/server/unique_jobs'
require 'rspec-sidekiq'

describe "When Sidekiq::Testing is enabled" do
  describe 'when set to :fake!', sidekiq: :fake do
    context "with unique worker" do
      it "does not push duplicate messages" do
        param = 'work'
        expect(UniqueWorker.jobs.size).to eq(0)
        UniqueWorker.perform_async(param)
        expect(UniqueWorker.jobs.size).to eq(1)
        expect(UniqueWorker).to have_enqueued_job(param)
        UniqueWorker.perform_async(param)
        expect(UniqueWorker.jobs.size).to eq(1)
      end
    end

    context "with non-unique worker" do

      it "pushes duplicates messages" do
        param = 'work'
        expect(MyWorker.jobs.size).to eq(0)
        MyWorker.perform_async(param)
        expect(MyWorker.jobs.size).to eq(1)
        expect(MyWorker).to have_enqueued_job(param)
        MyWorker.perform_async(param)
        expect(MyWorker.jobs.size).to eq(2)
      end
    end
  end
end
