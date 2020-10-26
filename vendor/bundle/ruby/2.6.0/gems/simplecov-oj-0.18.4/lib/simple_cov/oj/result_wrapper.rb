# frozen_string_literal: true

module SimpleCov
  module Oj
    #
    # Representation of the simplecov result including it's coverage data, source code,
    # source lines and featuring helpers to interpret that data.
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class ResultWrapper
      #
      # Wrap the SimpleCov::Result to enable hash conversion without monkey patching
      #
      # @param [SimpleCov::Result] result the simplecov result to generate hash for
      #
      def initialize(result)
        @result = result
      end

      #
      # Returns a nicely formatted hash from the simplecov result data
      #
      #
      # @return [Hash]
      #
      def to_h
        {
          covered_percent: covered_percent,
          covered_strength: covered_strength,
          covered_lines: covered_lines,
          total_lines: total_lines
        }
      end

      private

      attr_reader :result

      # @private
      def covered_strength
        return 0.0 unless (coverage = result.covered_strength)

        coverage.nan? ? 0.0 : coverage
      end

      # @private
      def covered_percent
        result.covered_percent
      end

      # @private
      def covered_lines
        result.covered_lines
      end

      # @private
      def total_lines
        result.total_lines
      end
    end
  end
end
