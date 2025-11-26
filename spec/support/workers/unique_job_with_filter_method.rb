# frozen_string_literal: true

# :nocov:

class UniqueJobWithFilterMethod
  include Sidekiq::Worker

  sidekiq_options backtrace: 10,
    lock: :while_executing,
    queue: :customqueue,
    retry: 1,
    lock_args_method: :lock_args

  def perform(*)
    # NO-OP
  end

  def self.lock_args(args)
    options = args.extract_options!
    [args.first, options["type"]]
  end
end
