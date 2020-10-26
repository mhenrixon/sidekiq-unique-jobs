# frozen_string_literal: true

module RSpec
  module Benchmark
    module Formatter
      # Format time for easy matcher reporting
      #
      # @param [Float] time
      #   the time to format
      #
      # @return [String]
      #   the human readable time value
      #
      # @api public
      def format_time(time)
        if time >= 100.0
          "%.0f sec" % [time]
        elsif time >= 1.0
          "%.3g sec" % [time]
        elsif time >= 1e-3
          "%.3g ms" % [time * 1e3]
        elsif time >= 1e-6
          "%.3g μs" % [time * 1e6]
        else
          "%.3g ns" % [time * 1e9]
        end
      end
      module_function :format_time

      UNITS = ([""] + %w[k M B T Q]).freeze

      # Format large numbers and replace thousands with a unit
      # for increased readability
      #
      # @param [Numeric] number
      #   the number to format
      #
      # @return [String]
      #
      # @api pubic
      def format_unit(number)
        scale = (Math.log10(number) / 3).to_i
        scale = 0 if scale > 5
        suffix = UNITS[scale]

        "%.3g#{suffix}" % [number.to_f / (1000 ** scale)]
      end
      module_function :format_unit
    end
  end # Benchmark
end # RSpec
