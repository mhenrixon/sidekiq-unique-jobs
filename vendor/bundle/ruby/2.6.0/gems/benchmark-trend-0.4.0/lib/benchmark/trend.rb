# frozen_string_literal: true

require_relative "trend/clock"
require_relative "trend/version"

module Benchmark
  module Trend
    # Change module function visiblity to private
    #
    # @api private
    def self.private_module_function(method)
      module_function(method)
      private_class_method(method)
    end

    # Generate a range of inputs spaced by powers.
    #
    # The default range is generated in the multiples of 8.
    #
    # @example
    #   Benchmark::Trend.range(8, 8 << 10)
    #   # => [8, 64, 512, 4096, 8192]
    #
    # @param [Integer] start
    # @param [Integer] limit
    # @param [Integer] ratio
    #
    # @api public
    def range(start, limit, ratio: 8)
      check_greater(start, 0)
      check_greater(limit, start)
      check_greater(ratio, 2)

      items = []
      count = start
      items << count
      (limit / ratio).times do
        count *= ratio
        break if count >= limit
        items << count
      end
      items << limit if start != limit
      items
    end
    module_function :range

    # Check if expected value is greater than minimum
    #
    # @param [Numeric] expected
    # @param [Numeric] min
    #
    # @raise [ArgumentError]
    #
    # @api private
    def check_greater(expected, min)
      unless expected >= min
        raise ArgumentError,
              "Range value: #{expected} needs to be greater than #{min}"
      end
    end
    private_module_function :check_greater

    # Gather times for each input against an algorithm
    #
    # @param [Array[Numeric]] data
    #   the data to run measurements for
    #
    # @param [Integer] repeat
    #   nubmer of times work is called to compute execution time
    #
    # @return [Array[Array, Array]]
    #
    # @api public
    def measure_execution_time(data = nil, repeat: 1, &work)
      inputs = data || range(1, 10_000)
      times  = []

      inputs.each_with_index do |input, i|
        GC.start
        measurements = []

        repeat.times do
          measurements << Clock.measure { work.(input, i) }
        end

        times << measurements.reduce(&:+).to_f / measurements.size
      end
      [inputs, times]
    end
    module_function :measure_execution_time

    # Finds a line of best fit that approximates linear function
    #
    # Function form: y = ax + b
    #
    # @param [Array[Numeric]] xs
    #   the data points along X axis
    #
    # @param [Array[Numeric]] ys
    #   the data points along Y axis
    #
    # @return [Numeric, Numeric, Numeric]
    #   return a slope, b intercept and rr correlation coefficient
    #
    # @api public
    def fit_linear(xs, ys)
      fit(xs, ys)
    end
    module_function :fit_linear

    # Find a line of best fit that approximates logarithmic function
    #
    # Model form: y = a*lnx + b
    #
    # @param [Array[Numeric]] xs
    #   the data points along X axis
    #
    # @param [Array[Numeric]] ys
    #   the data points along Y axis
    #
    # @return [Numeric, Numeric, Numeric]
    #   returns a, b, and rr values
    #
    # @api public
    def fit_logarithmic(xs, ys)
      fit(xs, ys, tran_x: ->(x) { Math.log(x) })
    end
    module_function :fit_logarithmic

    alias fit_log fit_logarithmic
    module_function :fit_log

    # Finds a line of best fit that approxmimates power function
    #
    # Function form: y = bx^a
    #
    # @return [Numeric, Numeric, Numeric]
    #   returns a, b, and rr values
    #
    # @api public
    def fit_power(xs, ys)
      a, b, rr = fit(xs, ys, tran_x: ->(x) { Math.log(x) },
                             tran_y: ->(y) { Math.log(y) })

      [a, Math.exp(b), rr]
    end
    module_function :fit_power

    # Find a line of best fit that approximates exponential function
    #
    # Model form: y = ab^x
    #
    # @return [Numeric, Numeric, Numeric]
    #   returns a, b, and rr values
    #
    # @api public
    def fit_exponential(xs, ys)
      a, b, rr = fit(xs, ys, tran_y: ->(y) { Math.log(y) })

      [Math.exp(a), Math.exp(b), rr]
    end
    module_function :fit_exponential

    alias fit_exp fit_exponential
    module_function :fit_exp

    # Fit the performance measurements to construct a model with
    # slope and intercept parameters that minimize the error.
    #
    # @param [Array[Numeric]] xs
    #   the data points along X axis
    #
    # @param [Array[Numeric]] ys
    #   the data points along Y axis
    #
    # @return [Array[Numeric, Numeric, Numeric]
    #   returns slope, intercept and model's goodness-of-fit
    #
    # @api public
    def fit(xs, ys, tran_x: ->(x) { x }, tran_y: ->(y) { y })
      eps    = (10 ** -10)
      n      = 0
      sum_x  = 0.0
      sum_x2 = 0.0
      sum_y  = 0.0
      sum_y2 = 0.0
      sum_xy = 0.0

      xs.zip(ys).each do |x, y|
        n        += 1
        sum_x    += tran_x.(x)
        sum_y    += tran_y.(y)
        sum_x2   += tran_x.(x) ** 2
        sum_y2   += tran_y.(y) ** 2
        sum_xy   += tran_x.(x) * tran_y.(y)
      end

      txy = n * sum_xy - sum_x * sum_y
      tx  = n * sum_x2 - sum_x ** 2
      ty  = n * sum_y2 - sum_y ** 2

      is_linear = tran_x.(Math::E) * tran_y.(Math::E) == Math::E ** 2

      if tx.abs < eps # no variation in xs
        raise ArgumentError, "No variation in data #{xs}"
      elsif ty.abs < eps && is_linear # no variation in ys - constant fit
        slope = 0
        intercept = sum_y / n
        residual_sq = 1 # doesn't exist
      else
        slope       = txy / tx
        intercept   = (sum_y - slope * sum_x) / n
        residual_sq = (txy ** 2) / (tx * ty)
      end

      [slope, intercept, residual_sq]
    end
    module_function :fit

    # Take a fit and estimate behaviour at input size n
    #
    # @example
    #   fit_at(:power, slope: 1.5, intercept: 2, n: 10)
    #
    # @return
    #   fit model value for input n
    #
    # @api public
    def fit_at(type, slope: nil, intercept: nil, n: nil)
      raise ArgumentError, "Incorrect input size: #{n}" unless n > 0

      case type
      when :logarithmic, :log
        intercept + slope * Math.log(n)
      when :linear
        intercept + slope * n
      when :power
        intercept * (n ** slope)
      when :exponential, :exp
        intercept * (slope ** n)
      else
        raise ArgumentError, "Unknown fit type: #{type}"
      end
    end
    module_function :fit_at

    # A mathematical notation template for a trend type
    #
    # @param [String] type
    #   the fit model type
    #
    # @return [String]
    #   the formatted mathematical function template
    #
    # @api private
    def format_fit(type)
      case type
      when :logarithmic, :log
        "%.2f + %.2f*ln(x)"
      when :linear, :constant
        "%.2f + %.2f*x"
      when :power
        "%.2f * x^%.2f"
      when :exponential, :exp
        "%.2f * %.2f^x"
      else
        raise ArgumentError, "Unknown type: '#{type}'"
      end
    end
    module_function :format_fit

    # the trends to consider
    FIT_TYPES = [:exponential, :power, :linear, :logarithmic]

    # Infer trend from the execution times
    #
    # Fits the executiom times for each range to several fit models.
    #
    # @param [Integer] repeat
    #   nubmer of times work is called to compute execution time
    #
    # @yieldparam work
    #   the block of which the complexity is measured
    #
    # @return [Array[Symbol, Hash]]
    #   the best fitting and all the trends
    #
    # @api public
    def infer_trend(data, repeat: 1, &work)
      ns, times = *measure_execution_time(data, repeat: repeat, &work)
      best_fit = :none
      best_residual = 0
      fitted = {}
      n = ns.size.to_f
      aic = -1.0/0
      best_aic = -1.0/0

      FIT_TYPES.each do |fit|
        a, b, rr = *send(:"fit_#{fit}", ns, times)
        # goodness of model
        aic = n * (Math.log(Math::PI) + 1) + n * Math.log(rr / n)
        if a == 0 && fit == :linear
          fit = :constant
        end
        fitted[fit] = { trend: format_fit(fit) % [a, b],
                        slope: a, intercept: b, residual: rr }
        if rr >= best_residual && aic >= best_aic
          best_residual = rr
          best_fit = fit
          best_aic = aic
        end
      end

      [best_fit, fitted]
    end
    module_function :infer_trend
  end # Trend
end # Benchmark
