# frozen_string_literal: true

require 'benchmark-trend'

module RSpec
  module Benchmark
    module ComplexityMatcher
      # Implements the `perform`
      #
      # @api public
      class Matcher
        def initialize(fit_type, **options)
          @fit_type  = fit_type
          @threshold = options.fetch(:threshold) {
                        RSpec::Benchmark.configuration.fit_quality }
          @repeat    = options.fetch(:repeat) {
                        RSpec::Benchmark.configuration.samples }
          @start     = 8
          @limit     = 8 << 10
          @ratio     = 8
        end

        # Indicates this matcher matches against a block
        #
        # @return [True]
        #
        # @api private
        def supports_block_expectations?
          true
        end

        def matcher_name
          "perform_#{@fit_type}"
        end

        # @return [Boolean]
        #
        # @api private
        def matches?(block)
          range = ::Benchmark::Trend.range(@start, @limit, ratio: @ratio)
          @trend, trends = ::Benchmark::Trend.infer_trend(range, repeat: @repeat, &block)
          threshold = trends[@trend][:residual]

          @trend == @fit_type && threshold >= @threshold
        end

        # Specify range of inputs
        #
        # @api public
        def in_range(start, limit = (not_set = true))
          case start
          when Array
            @start, *, @limit = *start
            @ratio = start[1] / start[0]
          when Numeric
            @start, @limit = start, limit
          else
            raise ArgumentError,
                "Wrong range argument '#{start}', it expects an array or numeric start value."
          end
          self
        end

        def threshold(threshold)
          @threshold = threshold
          self
        end

        def ratio(ratio)
          @ratio = ratio
          self
        end

        def sample(repeat)
          @repeat = repeat
          self
        end

        def actual
          @trend
        end

        # No-op, syntactic sugar.
        # @api public
        def times
          self
        end

        # @api private
        def description
          "perform #{@fit_type}"
        end

        # @api private
        def failure_message
          "expected block to #{description}, but #{failure_reason}"
        end

        def failure_message_when_negated
          "expected block not to #{description}, but #{failure_reason}"
        end

        def failure_reason
          "performed #{actual}"
        end
      end # Matcher
    end # ComplexityMatcher
  end # Benchmark
end # RSpec
