# frozen_string_literal: true

class UntilExecutedWithLockArgsJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  lock_args_method: :lock_args,
                  lock_timeout: 0,
                  lock_ttl: 600,
                  lock_limit: 2

  def self.lock_args(args)
    options = args.extract_options!
    [args[0], options["bogus"]]
  end

  def perform(*_args)
    logger.info("cowboy")
    sleep(1)
    logger.info("beebop")
  end
end
