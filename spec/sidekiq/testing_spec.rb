# frozen_string_literal: true

RSpec.describe "sidekiq/testing" do
  describe "Sidekiq::Worker.clear_all" do
    it "unlocks all unique locks" do
      expect(UntilAndWhileExecutingJob.perform_async).not_to be_nil
      Sidekiq::Worker.clear_all
      expect(UntilAndWhileExecutingJob.perform_async).not_to be_nil
    end
  end
end
