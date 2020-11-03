# frozen_string_literal: true

# :nocov:

class MyUniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
                  lock: :until_executed,
                  queue: :customqueue,
                  retry: true,
                  lock_args_method: :lock_args

  def perform(*)
    # NO-OP
  end

  def self.lock_args(args)
    options = args.extract_options!
    [args.first, options["type"]]
  end
end
