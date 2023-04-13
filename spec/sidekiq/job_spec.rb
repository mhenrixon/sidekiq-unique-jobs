# frozen_string_literal: true

RSpec.describe Sidekiq::Job do
  describe "#clear_all" do
    it "unlocks all unique locks" do
      expect(UntilAndWhileExecutingJob.perform_async).not_to be_nil
      described_class.clear_all
      expect(UntilAndWhileExecutingJob.perform_async).not_to be_nil
    end
  end
end
