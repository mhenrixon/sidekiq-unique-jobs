# frozen_string_literal: true

# This class will lock until the job is successfully executed
#
# It will wait for 0 seconds to acquire a lock and it will expire the unique key after 2 seconds
#
class UntilExecutedJob
  include Sidekiq::Worker
  sidekiq_options queue: :working,
                  retry: 1,
                  backtrace: 10,
                  unique: :until_executed,
                  lock_timeout: 0,
                  lock_expiration: nil

  def perform(one, two = nil)
    [one, two]
  end

  def after_unlock
    # NO OP
  end
end
