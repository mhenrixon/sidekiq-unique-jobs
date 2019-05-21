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

    #
    # Returns the current time as float
    #
    #
    # @return [Float]
    #
    def current_time
      if Process.const_defined?("CLOCK_MONOTONIC")
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      else
        Time.now.to_f
      end
    end

    def time_source
      proc { (current_time * 1000).to_i }
    end
  end
end
