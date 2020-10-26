# frozen_string_literal: true

require "benchmark-perf"

module RSpec
  module Benchmark
    module IterationMatcher
      # Implements the `perform_at_least` matcher
      #
      # @api private
      class Matcher
        def initialize(iterations, **options)
          @iterations = iterations
          @time       = options.fetch(:time) { 0.2 }
          @warmup     = options.fetch(:warmup) { 0.1 }
          @format     = options.fetch(:format) {
                          RSpec::Benchmark.configuration.format }
          @bench      = ::Benchmark::Perf
        end

        # Check if human format should be used
        #
        # @return [Boolean]
        #
        # @api private
        def human_format?
          @format == :human
        end

        # Indicates this matcher matches against a block
        #
        # @return [True]
        #
        # @api private
        def supports_block_expectations?
          true
        end

        # @return [Boolean]
        #
        # @api private
        def matches?(block)
          @average, @stddev, = @bench.ips(time: @time, warmup: @warmup, &block)
          @iterations <= (@average + 3 * @stddev)
        end

        # The time before measurements are taken
        #
        # @param [Numeric] value
        #   the time before measurements are taken
        #
        # @api public
        def warmup(value)
          @warmup = value
          self
        end

        # Time to measure iteration for
        #
        # @param [Numeric] value
        #   the time to take measurements for
        #
        # @api public
        def within(value)
          @time = value
          self
        end

        # Sugar syntax for iterations per second
        # @api public
        def ips
          self
        end

        def failure_message
          "expected block to #{description}, but #{positive_failure_reason}"
        end

        def failure_message_when_negated
          "expected block not to #{description}, but #{negative_failure_reason}"
        end

        def description
          iters = human_format? ? Formatter.format_unit(@iterations) : @iterations
          "perform at least #{iters} i/s"
        end

        def actual
          avg = human_format? ? Formatter.format_unit(@average) : @average
          "%s (± %d%%) i/s" % [avg, (@stddev / @average.to_f) * 100]
        end

        def positive_failure_reason
          "performed only #{actual}"
        end

        def negative_failure_reason
          "performed #{actual}"
        end
      end
    end # IterationMatcher
  end # Benchmark
end # RSpec
