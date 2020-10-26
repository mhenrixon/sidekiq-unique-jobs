# frozen_string_literal: true

require_relative "stats"

module Benchmark
  module Perf
    class CPUResult
      # Indicate no value
      NO_VALUE = Module.new

      # Create storage for ips results
      #
      # @api private
      def initialize
        @avg = NO_VALUE
        @stdev = NO_VALUE
        @dt = NO_VALUE
        @measurements = []
      end

      # @api private
      def add(time_s)
        @measurements << time_s
        @avg = NO_VALUE
        @stdev = NO_VALUE
        @dt = NO_VALUE
      end
      alias << add

      # Average ips
      #
      # @return [Integer]
      #
      # @api public
      def avg
        return @avg unless @avg == NO_VALUE

        @avg = Stats.average(@measurements)
      end

      # The ips standard deviation
      #
      # @return [Integer]
      #
      # @api public
      def stdev
        return @stdev unless @stdev == NO_VALUE

        @stdev = Stats.stdev(@measurements)
      end

      # The time elapsed
      #
      # @return [Float]
      #
      # @api public
      def dt
        return @dt unless @dt == NO_VALUE

        @dt = @measurements.reduce(0, :+)
      end
      alias elapsed_time dt

      # @api public
      def to_a
        [avg, stdev, dt]
      end
      alias to_ary to_a

      # A string representation of this instance
      #
      # @api public
      def inspect
        "#<#{self.class.name} @avg=#{avg} @stdev=#{stdev} @dt=#{dt}>"
      end
    end # IPSResult
  end # Perf
end # Benchmark
