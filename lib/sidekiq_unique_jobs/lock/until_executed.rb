# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuted < QueueLockBase
      OK ||= 'OK'

      extend Forwardable
      def_delegators :Sidekiq, :logger

      def execute(callback, &block)
        operative = true
        send(:after_yield_yield, &block)
      rescue Sidekiq::Shutdown
        operative = false
        raise
      ensure
        if operative && unlock(:server)
          callback.call
        else
          logger.fatal("the unique_key: #{@item[UNIQUE_DIGEST_KEY]} needs to be unlocked manually")
        end
      end

      def unlock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :server)

        @locksmith.unlock
        @locksmith.delete!
      end

      def lock(scope)
        validate_scope!(actual_scope: scope, expected_scope: :client)
        @locksmith.lock(@calculator.lock_timeout)
      end

      def after_yield_yield
        yield
      end
    end
  end
end
