# frozen_string_literal: true

# :nocov:

class UniqueJobWithoutUniqueArgsParameter
  include Sidekiq::Worker
  sidekiq_options backtrace: true,
                  lock: :until_executed,
                  queue: :customqueue,
                  retry: true,
                  lock_args_method: :unique_args

  def perform(optional = true) # rubocop:disable Style/OptionalBooleanParameter
    optional
    # NO-OP
  end

  def self.unique_args; end
end
