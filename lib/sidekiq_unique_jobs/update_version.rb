# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class UpdateVersion sets the right version in redis
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class UpdateVersion
    def self.call
      Script::Caller.call_script(
        :set_version,
        keys: [LIVE_VERSION, DEAD_VERSION],
        argv: [SidekiqUniqueJobs.version],
      )
    end
  end
end
