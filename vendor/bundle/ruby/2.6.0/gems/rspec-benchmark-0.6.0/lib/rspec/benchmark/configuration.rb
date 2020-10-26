# frozen_string_literal: true

module RSpec
  module Benchmark
    class Configuration
      # Isolate benchmark time measurement in child process
      # By default false due to Rails loosing DB connections
      #
      # @api public
      attr_accessor :run_in_subprocess

      # GC is enabled to measure real performance
      #
      # @api public
      attr_accessor :disable_gc

      # How many times to repeat measurements
      #
      # @return [Integer]
      #
      # @api public
      attr_accessor :samples

      # The fit quality in computational complexity
      #
      # @return [Float]
      #
      # @api public
      attr_accessor :fit_quality

      # The formatting for number of iterations
      #
      # @return [String]
      #
      # @api public
      attr_accessor :format

      # @api private
      def initialize
        @disable_gc  = false
        @samples     = 1
        @fit_quality = 0.9
        @format      = :human
        @run_in_subprocess = false
      end
    end # Configuration
  end # Benchmark
end # RSpec
