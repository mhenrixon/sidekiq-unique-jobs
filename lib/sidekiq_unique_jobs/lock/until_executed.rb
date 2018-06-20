# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuted < BaseLock
      OK ||= 'OK'

      def execute(callback, &block)
        operative = true
        send(:after_yield_yield, &block)
      rescue Sidekiq::Shutdown
        operative = false
        raise
      ensure
        if operative && unlock
          callback.call
        else
          log_fatal("the unique_key: #{@item[UNIQUE_DIGEST_KEY]} needs to be unlocked manually")
        end
      end

      def after_yield_yield
        yield
      end
    end
  end
end
