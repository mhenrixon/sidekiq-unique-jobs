# frozen_string_literal: true

module SidekiqUniqueJobs
  module Fetch
    # Wraps a Sidekiq UnitOfWork with lock-aware acknowledge and requeue behavior.
    #
    # - {#acknowledge} confirms lock cleanup after successful job completion (safety net)
    # - {#requeue} preserves locks when jobs are returned to the queue during shutdown
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class LockAwareUnitOfWork
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Reflectable
      include SidekiqUniqueJobs::JSON

      # @return [Object] the wrapped inner UnitOfWork
      attr_reader :inner_work

      # @param inner_work [Object] a Sidekiq UnitOfWork (BasicFetch::UnitOfWork, etc.)
      def initialize(inner_work)
        @inner_work = inner_work
        @acknowledged = false
      end

      def queue
        inner_work.queue
      end

      def job
        inner_work.job
      end

      def config
        inner_work.config
      end

      def queue_name
        inner_work.queue_name
      end

      # Called after successful job completion.
      # Delegates to the inner UnitOfWork, then confirms lock cleanup as a safety net.
      def acknowledge
        return if @acknowledged

        @acknowledged = true
        inner_work.acknowledge
        confirm_lock_cleanup
      end

      # Called to return a job to the queue (e.g. during shutdown).
      # Delegates to the inner UnitOfWork but does NOT release the lock —
      # the job is going back to the queue and the lock must persist.
      def requeue
        inner_work.requeue
        reflect(:lock_preserved_on_requeue, parsed_job) if unique_job?
      end

      private

      def parsed_job
        @parsed_job ||= safe_load_json(job)
      end

      def unique_job?
        parsed_job.is_a?(Hash) && parsed_job.key?(LOCK_DIGEST)
      end

      def confirm_lock_cleanup
        return unless unique_job?

        digest = parsed_job[LOCK_DIGEST]
        jid = parsed_job[JID]
        return unless digest && jid

        locksmith = SidekiqUniqueJobs::Locksmith.new(parsed_job)
        return unless locksmith.locked?

        log_warn("Lock still held after acknowledge, releasing as safety net: " \
                 "digest=#{digest} jid=#{jid}")
        locksmith.unlock
        reflect(:lock_cleanup_on_ack, parsed_job)
      rescue StandardError => ex
        log_warn("Failed to confirm lock cleanup: #{ex.message}")
      end
    end
  end
end
