# frozen_string_literal: true

# :nocov:

require_relative "./custom_queue_job"

class CustomQueueJobWithFilterProc < CustomQueueJob
  # slightly contrived example of munging args to the
  # worker and removing a random bit.
  sidekiq_options lock: :until_expired,
                  unique_args: (lambda do |args|
                    options = args.extract_options!
                    options.delete("random")
                    args + [options]
                  end)
end
