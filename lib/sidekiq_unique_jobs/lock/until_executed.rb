# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class UntilExecuted < BaseLock
      OK ||= 'OK'

      def execute(callback)
        return unless locked?
        using_protection(callback) do
          yield if block_given?
        end
      end
    end
  end
end
