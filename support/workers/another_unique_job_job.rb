# frozen_string_literal: true

# :nocov:
if Sidekiq.const_defined?("JobRecord")
  require "sidekiq/job"
  # This class is here to test sidekiq 6.2.2 compatibility
  class AnotherUniqueJobJob
    include Sidekiq::Job
    sidekiq_options backtrace: 10,
                    lock: :until_executed,
                    queue: :working2,
                    retry: 1

    def perform(args)
      args
    end
  end
end
