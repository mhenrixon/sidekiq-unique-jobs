# frozen_string_literal: true

module SidekiqUniqueJobs
  # Handles timing of things
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Timing
    module_function

    #
    # Used for timing method calls
    #
    #
    # @return [yield return, Float]
    #
    def timed
      start_time = time_source.call

      [yield, time_source.call - start_time]
    end

    def time_source
      lambda do
        (clock_stamp * 1000).to_i
      end
    end

    def now_f
      SidekiqUniqueJobs.now_f
    end

    def clock_stamp
      if Process.const_defined?("CLOCK_MONOTONIC")
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      else
        Time.now.to_f
      end
    end
  end
end
