# frozen_string_literal: true

# :nocov:

class MyUniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue,
                  retry: true,
                  backtrace: true,
                  unique: :until_executed,
                  unique_args: :filtered_args

  def perform(*)
    # NO-OP
  end

  def self.filtered_args(args)
    options = args.extract_options!
    [args.first, options['type']]
  end
end
