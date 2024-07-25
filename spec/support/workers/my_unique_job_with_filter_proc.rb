# frozen_string_literal: true

# :nocov:

class MyUniqueJobWithFilterProc
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
    lock: :until_executed,
    queue: :customqueue,
    retry: true,
    lock_args_method: (lambda do |args|
      options = args.extract_options!
      [args.first, options["type"]]
    end)

  def perform(*)
    # NO-OP
  end
end
