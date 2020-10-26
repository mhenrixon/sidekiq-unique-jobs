# frozen_string_literal: true

require "benchmark-perf"

require_relative "formatter"

module RSpec
  module Benchmark
    module TimingMatcher
      # Implements the `perform_under` matcher
      #
      # @api private
      class Matcher
        include RSpec::Benchmark

        attr_reader :threshold

        def initialize(threshold, **options)
          @threshold = threshold
          @samples   = options.fetch(:samples) {
                         RSpec::Benchmark.configuration.samples
                       }
          @warmup    = options.fetch(:warmup) { 1 }
          @subprocess = options.fetch(:subprocess) {
                          RSpec::Benchmark.configuration.run_in_subprocess
                        }
          @scale     = threshold.to_s.split(/\./).last.size
          @block     = nil
          @bench     = ::Benchmark::Perf
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
          @block = block
          return false unless block.is_a?(Proc)
          @average, @stddev = @bench.cpu(repeat: @samples, warmup: @warmup,
                                         subprocess: @subprocess, &block)
          @average <= @threshold
        end

        def does_not_match?(block)
          !matches?(block) && block.is_a?(Proc)
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

        # How many times to repeat measurement
        #
        # @param [Integer] samples
        #   the number of times to repeat the measurement
        #
        # @api public
        def sample(samples)
          @samples = samples
          self
        end

        # No-op, syntactic sugar.
        # @api public
        def times
          self
        end

        def secs
          self
        end
        alias sec secs

        # Tell this matcher to convert threshold to ms
        # @api public
        def ms
          @threshold /= 1e3
          self
        end

        # Tell this matcher to convert threshold to us
        # @api public
        def us
          @threshold /= 1e6
          self
        end

        # Tell this matcher to convert threshold to ns
        # @api public
        def ns
          @threshold /= 1e9
          self
        end

        def failure_message
          "expected block to #{description}, but #{positive_failure_reason}"
        end

        def failure_message_when_negated
          "expected block to not #{description}, but #{negative_failure_reason}"
        end

        def description
          "perform under #{Formatter.format_time(@threshold)}"
        end

        def actual
          "#{Formatter.format_time(@average)} (± #{Formatter.format_time(@stddev)})"
        end

        def positive_failure_reason
          return "was not a block" unless @block.is_a?(Proc)
          "performed above #{actual} "
        end

        def negative_failure_reason
          return "was not a block" unless @block.is_a?(Proc)
          "performed #{actual} under"
        end
      end # Matcher
    end # TiminingMatcher
  end # Benchmark
end # RSpec
