# frozen_string_literal: true

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Timing
    module_function

    def timed
      start_time = time_source.call

      [yield, time_source.call - start_time]
    end

    def current_time
      if defined?(Process::CLOCK_MONOTONIC)
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      else
        Time.now.to_f
      end
    end

    def time_source
      if defined?(Process::CLOCK_MONOTONIC)
        proc { (current_time * 1000).to_i }
      else
        proc { (current_time * 1000).to_i }
      end
    end
  end
end
