# frozen_string_literal: true

require_relative "on_conflict/strategy"
require_relative "on_conflict/null_strategy"
require_relative "on_conflict/log"
require_relative "on_conflict/raise"
require_relative "on_conflict/reject"
require_relative "on_conflict/replace"
require_relative "on_conflict/reschedule"

module SidekiqUniqueJobs
  #
  # Provides lock conflict resolutions
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  module OnConflict
    # A convenience method for using the configured strategies
    def self.strategies
      SidekiqUniqueJobs.strategies
    end

    # returns OnConflict::NullStrategy when no other could be found
    def self.find_strategy(strategy)
      strategies.fetch(strategy.to_s.to_sym) { OnConflict::NullStrategy }
    end
  end
end
