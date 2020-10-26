# frozen_string_literal: true

module Benchmark
  module Perf
    module Stats
      # Calculate arithemtic average of measurements
      #
      # @param [Array[Float]] measurements
      #
      # @return [Float]
      #   the average of given measurements
      #
      # @api public
      def average(measurements)
        return 0 if measurements.empty?

        measurements.reduce(&:+).to_f / measurements.size
      end
      module_function :average

      # Calculate variance of measurements
      #
      # @param [Array[Float]] measurements
      #
      # @return [Float]
      #
      # @api public
      def variance(measurements)
        return 0 if measurements.empty?

        avg = average(measurements)
        total = measurements.reduce(0) do |sum, x|
          sum + (x - avg)**2
        end
        total.to_f / measurements.size
      end
      module_function :variance

      # Calculate standard deviation
      #
      # @param [Array[Float]] measurements
      #
      # @api public
      def stdev(measurements)
        return 0 if measurements.empty?

        Math.sqrt(variance(measurements))
      end
      module_function :stdev
    end # Stats
  end # Perf
end # Benchmark
