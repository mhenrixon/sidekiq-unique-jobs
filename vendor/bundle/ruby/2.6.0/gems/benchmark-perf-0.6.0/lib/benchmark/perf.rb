# frozen_string_literal: true

require_relative "perf/execution"
require_relative "perf/iteration"
require_relative "perf/version"

module Benchmark
  module Perf
    # Measure iterations a work could take in a second
    #
    # @example
    #   Benchmark::Perf.ips { "foo" + "bar" }
    #
    # @param [Numeric] time
    #   the time to run measurements in seconds
    # @param [Numeric] warmup
    #   the warmup time in seconds
    #
    # @return [Array[Integer, Integer, Integer, Float]]
    #   the average, standard deviation, iterations and time
    #
    # @api public
    def ips(**options, &work)
      Iteration.run(**options, &work)
    end
    module_function :ips

    # Measure execution time(a.k.a cpu time) of a given work
    #
    # @example
    #   Benchmark::Perf.cpu { "foo" + "bar" }
    #
    # @param [Numeric] time
    #   the time to run measurements in seconds
    # @param [Numeric] warmup
    #   the warmup time in seconds
    # @param [Integer] repeat
    #   how many times to repeat measurements
    #
    # @return [Array[Float, Float]]
    #
    # @api public
    def cpu(**options, &work)
      Execution.run(**options, &work)
    end
    module_function :cpu
  end # Perf
end # Benchmark
