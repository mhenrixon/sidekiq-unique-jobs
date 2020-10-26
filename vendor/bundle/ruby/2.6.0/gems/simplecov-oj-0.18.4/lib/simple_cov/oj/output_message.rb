# frozen_string_literal: true

module SimpleCov
  module Oj
    #
    # Generates a nicely formatted string about generated coverage
    #
    # @author Mikael Henriksson <mikael@mhenrixon.se>
    #
    class OutputMessage
      #
      # Initialize a new OutputMessage
      #
      # @param [SimplCov::Result] result the final simplecov result
      # @param [String] output_filepath path to the filename
      #
      def initialize(result, output_filepath)
        @result          = result
        @output_filepath = output_filepath
      end

      #
      # Returns a nicely formatted string about the generated coverage data
      #
      #
      # @return [String]
      #
      def to_s
        'Coverage report generated' \
        " for #{command_name}" \
        " to #{output_filepath}." \
        " #{covered_lines} / #{total_lines} LOC (#{covered_percent.round(2)}%) covered."
      end
      alias inspect to_s

      private

      attr_reader :result, :output_filepath

      def command_name
        result.command_name
      end

      def covered_lines
        result.total_lines
      end

      def total_lines
        result.total_lines
      end

      def covered_percent
        result.covered_percent
      end
    end
  end
end
