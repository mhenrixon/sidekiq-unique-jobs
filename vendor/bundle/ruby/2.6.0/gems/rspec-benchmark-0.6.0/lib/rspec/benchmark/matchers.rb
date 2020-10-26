# frozen_string_literal: true

require_relative "allocation_matcher"
require_relative "comparison_matcher"
require_relative "complexity_matcher"
require_relative "iteration_matcher"
require_relative "timing_matcher"

module RSpec
  module Benchmark
    # Provides a number of useful performance testing expectations
    #
    # These matchers can be exposed by including the this module in
    # a spec:
    #
    #   RSpec.describe "Performance testing" do
    #     include RSpec::Benchmark::Matchers
    #   end
    #
    # or you can include in globablly in a spec_helper.rb file:
    #
    #   RSpec.configure do |config|
    #     config.inlucde(RSpec::Benchmark::Matchers)
    #   end
    #
    # @api public
    module Matchers
      # Passes if code block performs at least iterations
      #
      # @param [Integer] iterations
      #
      # @example
      #   expect { ... }.to perform_allocation(10000)
      #   expect { ... }.to perform_allocation(10000)
      #
      # @api public
      def perform_allocation(objects, **options)
        AllocationMatcher::Matcher.new(objects, **options)
      end

      # Passes if code block performs at least iterations
      #
      # @param [Integer] iterations
      #
      # @example
      #   expect { ... }.to perform_at_least(10000)
      #   expect { ... }.to perform_at_least(10000).ips
      #
      # @api public
      def perform_at_least(iterations, **options)
        IterationMatcher::Matcher.new(iterations, **options)
      end

      # Passes if code block performs under threshold
      #
      # @param [Float] threshold
      #
      # @example
      #   expect { ... }.to peform_under(0.001)
      #   expect { ... }.to peform_under(0.001).sec
      #   expect { ... }.to peform_under(10).ms
      #
      # @api public
      def perform_under(threshold, **options)
        TimingMatcher::Matcher.new(threshold, **options)
      end

      # Passes if code block performs faster than sample block
      #
      # @param [Proc] sample
      #
      # @example
      #   expect { ... }.to peform_faster_than { ... }
      #   expect { ... }.to peform_faster_than { ... }.at_least(5).times
      #
      # @api public
      def perform_faster_than(**options, &sample)
        ComparisonMatcher::Matcher.new(sample, :faster, **options)
      end

      # Passes if code block performs slower than sample block
      #
      # @param [Proc] sample
      #
      # @example
      #   expect { ... }.to peform_slower_than { ... }
      #   expect { ... }.to peform_slower_than { ... }.at_most(5).times
      #
      # @api public
      def perform_slower_than(**options, &sample)
        ComparisonMatcher::Matcher.new(sample, :slower, **options)
      end

      # Pass if code block performs constant
      #
      # @example
      #   expect { ... }.to perform_constant
      #   expect { ... }.to perform_constant.within(1, 100_000)
      #   expect { ... }.to perform_constant.within(1, 100_000, ratio: 4)
      #
      # @api public
      def perform_constant(**options)
        ComplexityMatcher::Matcher.new(:constant, **options)
      end

      # Pass if code block performs logarithmic
      #
      # @example
      #   expect { ... }.to perform_logarithmic
      #   expect { ... }.to perform_logarithmic
      #   expect { ... }.to perform_logarithmic.within(1, 100_000)
      #   expect { ... }.to perform_logarithimic.within(1, 100_000, ratio: 4)
      #
      # @api public
      def perform_logarithmic(**options)
        ComplexityMatcher::Matcher.new(:logarithmic, **options)
      end
      alias perform_log perform_logarithmic

      # Pass if code block performs linear
      #
      # @example
      #   expect { ... }.to perform_linear
      #   expect { ... }.to perform_linear.within(1, 100_000)
      #   expect { ... }.to perform_linear.within(1, 100_000, ratio: 4)
      #
      # @api public
      def perform_linear(**options)
        ComplexityMatcher::Matcher.new(:linear, **options)
      end

      # Pass if code block performs power
      #
      # @example
      #   expect { ... }.to perform_power
      #   expect { ... }.to perform_power.within(1, 100_000)
      #   expect { ... }.to perform_power.within(1, 100_000, ratio: 4)
      #
      # @api public
      def perform_power(**options)
        ComplexityMatcher::Matcher.new(:power, **options)
      end

      # Pass if code block performs exponential
      #
      # @example
      #   expect { ... }.to perform_exponential
      #   expect { ... }.to perform_exponential.within(1, 100_000)
      #   expect { ... }.to perform_exponential.within(1, 100_000, ratio: 4)
      #
      # @api public
      def perform_exponential(**options)
        ComplexityMatcher::Matcher.new(:exponential, **options)
      end
      alias perform_exp perform_exponential

      # Generate a geometric progression of inputs
      #
      # The default range is generated in the multiples of 8.
      #
      # @example
      #   bench_range(8, 8 << 10)
      #   # => [8, 64, 512, 4096, 8192]
      #
      # @param [Integer] start
      # @param [Integer] limit
      # @param [Integer] ratio
      #
      # @api public
      def bench_range(*args)
        ::Benchmark::Trend.range(*args)
      end
    end # Matchers
  end # Benchmark
end # RSpec
