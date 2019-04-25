# frozen_string_literal: true

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Timing
    def timed
      start   = current_time
      result  = yield
      elapsed = (current_time - start)

      [result, elapsed]
    end

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
