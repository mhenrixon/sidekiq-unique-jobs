# frozen_string_literal: true
# :nocov:

class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue, retry: 1, backtrace: 10,
                  unique: :while_executing, unique_args: :filtered_args

  def perform(*)
    # NO-OP
  end

  def self.filtered_args(args)
    options = args.extract_options!
    [args.first, options['type']]
  end
end
