# frozen_string_literal: true

require_relative "stats"

module Benchmark
  module Perf
    class IPSResult
      # Indicate no value
      NO_VALUE = Module.new

      attr_reader :ips

      attr_reader :iter

      # Create storage for ips results
      #
      # @api private
      def initialize
        @avg = NO_VALUE
        @stdev = NO_VALUE
        @dt = NO_VALUE
        @measurements = []
        @ips = []
        @iter = 0
      end

      # @api private
      def add(time_s, cycles_in_100ms)
        @measurements << time_s
        @iter += cycles_in_100ms
        @ips << cycles_in_100ms.to_f / time_s.to_f
        @avg = NO_VALUE
        @stdev = NO_VALUE
        @dt = NO_VALUE
      end

      # Average ips
      #
      # @return [Integer]
      #
      # @api public
      def avg
        return @avg unless @avg == NO_VALUE

        @avg = Stats.average(ips).round
      end

      # The ips standard deviation
      #
      # @return [Integer]
      #
      # @api public
      def stdev
        return @stdev unless @stdev == NO_VALUE

        @stdev = Stats.stdev(ips).round
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
        [avg, stdev, iter, dt]
      end
      alias to_ary to_a

      # A string representation of this instance
      #
      # @api public
      def inspect
        "#<#{self.class.name} @avg=#{avg} @stdev=#{stdev} @iter=#{iter} @dt=#{dt}>"
      end
    end # IPSResult
  end # Perf
end # Benchmark
