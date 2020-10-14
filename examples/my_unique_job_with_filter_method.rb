# frozen_string_literal: true

# :nocov:

class MyUniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
                  lock: :until_executed,
                  queue: :customqueue,
                  retry: true,
                  unique_args: :filtered_args

  def perform(*)
    # NO-OP
  end

  def self.filtered_args(args, _item)
    options = args.extract_options!
    [args.first, options["type"]]
  end
end
