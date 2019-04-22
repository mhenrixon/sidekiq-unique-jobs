# frozen_string_literal: true

# :nocov:

class MyUniqueJobWithFilterProc
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
                  lock: :until_executed,
                  queue: :customqueue,
                  retry: true,
                  unique_args: (lambda do |args|
                    options = args.extract_options!
                    [args.first, options["type"]]
                  end)

  def perform(*)
    # NO-OP
  end
end
