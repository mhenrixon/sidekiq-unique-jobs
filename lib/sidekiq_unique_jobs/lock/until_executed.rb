# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuted < BaseLock
      OK ||= 'OK'

      def execute(callback)
        @operative = true
        yield if block_given?
      rescue Sidekiq::Shutdown
        @operative = false
        raise
      ensure
        unlock_and_callback(callback)
      end

      private

      def unlock_and_callback(callback)
        return notify_about_manual_unlock unless @operative
        unlock

        return notify_about_manual_unlock if locked?
        callback.call
      end

      def notify_about_manual_unlock
        log_fatal("the unique_key: #{@item[UNIQUE_DIGEST_KEY]} needs to be unlocked manually")
      end
    end
  end
end
