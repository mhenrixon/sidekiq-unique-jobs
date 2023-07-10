# frozen_string_literal: true

# :nocov:

require_relative "custom_queue_job"

class CustomQueueJobWithFilterProc < CustomQueueJob
  # slightly contrived example of munging args to the
  # worker and removing a random bit.
  sidekiq_options lock: :until_expired,
                  lock_args_method: (lambda do |args|
                    [args[0], args[1]["name"]]
                  end)
end
