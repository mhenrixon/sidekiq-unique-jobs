# frozen_string_literal: true

module SidekiqUniqueJobs
  module Fetch
    # Lock-aware fetch strategy that wraps any inner fetch (BasicFetch, SuperFetch, etc.)
    # with lock lifecycle management.
    #
    # Features:
    # - Advisory lock validation at fetch time (warns if lock TTL expired in queue)
    # - Lock-aware acknowledge (safety net for lock cleanup)
    # - Lock-preserving requeue (during shutdown, locks persist for requeued jobs)
    #
    # @example Configuration
    #   Sidekiq.configure_server do |config|
    #     config[:fetch_class] = SidekiqUniqueJobs::Fetch::LockAware
    #     # Optional: wrap SuperFetch instead of BasicFetch
    #     # config[:inner_fetch_class] = Sidekiq::Pro::SuperFetch
    #   end
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class LockAware
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Reflectable
      include SidekiqUniqueJobs::JSON

      # @param capsule [Sidekiq::Capsule] the Sidekiq capsule
      def initialize(capsule)
        inner_class = capsule.config[:inner_fetch_class] || Sidekiq::BasicFetch
        @inner_fetch = inner_class.new(capsule)
      end

      # Fetches the next job from the inner fetch, wraps it in a lock-aware UnitOfWork,
      # and validates the lock state.
      #
      # @return [LockAwareUnitOfWork, nil] the wrapped unit of work, or nil if no work
      def retrieve_work
        work = @inner_fetch.retrieve_work
        return unless work

        wrapped = LockAwareUnitOfWork.new(work)
        validate_lock_at_fetch(wrapped)
        wrapped
      end

      # Called during shutdown to return in-progress jobs to their queues.
      # Unwraps LockAwareUnitOfWork before delegating to the inner fetch.
      # Locks are intentionally preserved for requeued jobs.
      #
      # @param inprogress [Array<LockAwareUnitOfWork>] jobs to requeue
      def bulk_requeue(inprogress)
        inner_units = inprogress.map do |uow|
          uow.is_a?(LockAwareUnitOfWork) ? uow.inner_work : uow
        end

        @inner_fetch.bulk_requeue(inner_units)
      end

      # Forward setup calls for SuperFetch compatibility
      def setup(config_data)
        @inner_fetch.setup(config_data) if @inner_fetch.respond_to?(:setup)
      end

      private

      def validate_lock_at_fetch(wrapped)
        parsed = wrapped.send(:parsed_job)
        return unless parsed.is_a?(Hash)

        digest = parsed[LOCK_DIGEST]
        return unless digest

        Sidekiq.redis do |conn|
          unless conn.call("EXISTS", digest).positive?
            reflect(:lock_expired_at_fetch, parsed)
            log_warn("Lock expired before fetch (digest=#{digest}), job will still execute")
          end
        end
      rescue StandardError => ex
        log_warn("Lock validation at fetch failed: #{ex.message}")
      end
    end
  end
end
