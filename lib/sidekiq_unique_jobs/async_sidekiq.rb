# frozen_string_literal: true

module SidekiqUniqueJobs
  module AsyncSidekiq
    def run
      Async { super }
    end
  end
end

require "sidekiq/cli"
Sidekiq::CLI.prepend(SidekiqUniqueJobs::AsyncSidekiq)
