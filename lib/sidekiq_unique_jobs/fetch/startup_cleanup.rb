# frozen_string_literal: true

module SidekiqUniqueJobs
  module Fetch
    # Runs once on Sidekiq startup to immediately clean up orphaned locks
    # from previous process runs (crashes, OOM kills, deploys).
    #
    # This is complementary to the periodic reaper — it runs immediately
    # rather than waiting for the reaper interval (default 600s).
    #
    # Conservative: only cleans locks where the owning JID is not found
    # in any active Sidekiq process's work set.
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    module StartupCleanup
      module_function

      include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Reflectable
      include SidekiqUniqueJobs::JSON

      # @return [Integer] maximum number of digests to scan per startup
      MAX_SCAN = 1_000

      # Run the startup cleanup
      def call
        return unless SidekiqUniqueJobs.config.lock_aware_fetch

        log_info("Running startup lock cleanup")

        cleaned = 0
        digests = SidekiqUniqueJobs::Digests.new

        active_jids = collect_active_jids

        redis do |conn|
          digests.entries(count: MAX_SCAN).each_key do |digest|
            key = SidekiqUniqueJobs::Key.new(digest)
            locked_jids = conn.call("HGETALL", key.locked)

            next if locked_jids.empty?

            locked_jids.each_slice(2) do |jid, _score|
              next if active_jids.include?(jid)
              next if in_queue_or_set?(conn, digest)

              log_info("Cleaning orphaned lock: digest=#{digest} jid=#{jid}")
              item = { JID => jid, LOCK_DIGEST => digest }
              SidekiqUniqueJobs::Locksmith.new(item).unlock
              reflect(:orphan_lock_cleaned, item)
              cleaned += 1
            end
          end
        end

        log_info("Startup cleanup complete: #{cleaned} orphaned locks released") if cleaned.positive?
      rescue StandardError => ex
        log_warn("Startup lock cleanup failed: #{ex.message}")
      end

      # Collect all JIDs currently being processed by active Sidekiq processes
      def collect_active_jids
        jids = Set.new

        Sidekiq.redis do |conn|
          procs = conn.call("SMEMBERS", "processes")
          procs.each do |process_key|
            workers = conn.call("HGETALL", "#{process_key}:work")
            workers.each_slice(2) do |_tid, work_json|
              work = safe_load_json(work_json)
              next unless work.is_a?(Hash)

              payload = safe_load_json(work[PAYLOAD] || "{}")
              next unless payload.is_a?(Hash)

              jids << payload[JID] if payload[JID]
            end
          end
        end

        jids
      end

      # Check if a digest has a matching job in any queue, schedule, or retry set
      def in_queue_or_set?(conn, digest)
        # Check retry set
        conn.call("ZSCAN", RETRY, "0", "MATCH", "*#{digest}*", "COUNT", "100").last.any? ||
          # Check schedule set
          conn.call("ZSCAN", SCHEDULE, "0", "MATCH", "*#{digest}*", "COUNT", "100").last.any?
      end
    end
  end
end
