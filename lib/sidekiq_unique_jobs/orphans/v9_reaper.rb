# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    # v9 reaper: scans the digests ZSET and removes entries whose
    # LOCKED hash no longer exists (expired via TTL or process crash).
    #
    # This replaces both the Ruby and Lua reapers from v8.
    # The check is trivial: EXISTS on digest:LOCKED. If 0, ZREM.
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class V9Reaper < Reaper
      def call
        call_script(
          :reap_v9,
          conn,
          keys: [DIGESTS],
          argv: [reaper_count],
        )
      end
    end
  end
end
