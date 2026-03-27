# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Class DeleteOrphans provides deletion of orphaned digests
    #
    # @note this is faster than the ruby reaper but may block redis while executing
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class LuaReaper < Reaper
      #
      # Delete orphaned digests
      #
      #
      # @return [Integer] the number of reaped locks
      #
      def call
        call_script(
          :reap_orphans,
          conn,
          keys: [DIGESTS, EXPIRING_DIGESTS, SCHEDULE, RETRY, PROCESSES],
          argv: [reaper_count, (Time.now - reaper_timeout).to_f],
        )
      end
    end
  end
end
