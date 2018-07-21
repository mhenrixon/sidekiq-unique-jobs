# frozen_string_literal: true

# :nocov:

# This class will lock until the job is successfully executed
#
# It will wait for 0 seconds to acquire a lock and it will expire the unique key after 2 seconds
#
class UntilExecuted2Job
  include Sidekiq::Worker
  sidekiq_options backtrace: 10,
                  lock: :until_executed,
                  lock_timeout: 0,
                  queue: :working,
                  retry: 1

  def perform(one, two)
    [one, two]
  end

  def after_unlock
    # NO OP
  end
end
