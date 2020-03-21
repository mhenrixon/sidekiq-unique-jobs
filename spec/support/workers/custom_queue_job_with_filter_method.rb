# frozen_string_literal: true

# :nocov:

require_relative "custom_queue_job"

class CustomQueueJobWithFilterMethod < CustomQueueJob
  sidekiq_options lock: :until_executed, lock_args: :args_filter

  def self.args_filter(args)
    args.first
  end
end
