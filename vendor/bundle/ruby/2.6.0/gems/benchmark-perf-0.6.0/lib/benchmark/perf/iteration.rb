# frozen_string_literal: true

require_relative "clock"
require_relative "stats"
require_relative "ips_result"

module Benchmark
  module Perf
    # Measure number of iterations a work could take in a second
    #
    # @api private
    module Iteration
      # Call work by given times
      #
      # @param [Integer] times
      #   the times to call
      #
      # @return [Integer]
      #   the number of times worke has been called
      #
      # @api private
      def call_times(times)
        i = 0
        while i < times
          yield
          i += 1
        end
      end
      module_function :call_times

      # Calcualte the number of cycles needed for 100ms
      #
      # @param [Integer] iterations
      # @param [Float] time_s
      #   the total time for all iterations in seconds
      #
      # @return [Integer]
      #   the cycles per 100ms
      #
      # @api private
      def cycles_per_100ms(iterations, time_s)
        cycles = iterations * Clock::MICROSECONDS_PER_100MS
        cycles /= time_s * Clock::MICROSECONDS_PER_SECOND
        cycles = cycles.to_i
        cycles <= 0 ? 1 : cycles
      end
      module_function :cycles_per_100ms

      # Warmup run
      #
      # @param [Numeric] warmup
      #   the number of seconds for warmup
      #
      # @api private
      def run_warmup(warmup: 1, &work)
        GC.start

        target = Clock.now + warmup
        iter = 0

        time_s = Clock.measure do
          while Clock.now < target
            call_times(1, &work)
            iter += 1
          end
        end

        cycles_per_100ms(iter, time_s)
      end
      module_function :run_warmup

      # Run measurements
      #
      # @param [Numeric] time
      #   the time to run measurements in seconds
      # @param [Numeric] warmup
      #   the warmup time in seconds
      #
      # @api public
      def run(time: 2, warmup: 1, &work)
        cycles_in_100ms = run_warmup(warmup: warmup, &work)

        GC.start

        result = IPSResult.new

        target = (before = Clock.now) + time

        while Clock.now < target
          time_s = Clock.measure { call_times(cycles_in_100ms, &work) }

          next if time_s <= 0.0 # Iteration took no time

          result.add(time_s, cycles_in_100ms)
        end

        result
      end
      module_function :run
    end # Iteration
  end # Perf
end # Benchmark
