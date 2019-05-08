module SidekiqUniqueJobs
  module AsyncSidekiq
    def run
      binding.pry
      Async { super }
    end
  end
end

require 'sidekiq/cli'
Sidekiq::CLI.prepend(SidekiqUniqueJobs::AsyncSidekiq)
