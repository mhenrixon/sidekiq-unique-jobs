# frozen_string_literal: true

require_relative "benchmark/configuration"
require_relative "benchmark/matchers"
require_relative "benchmark/version"

module RSpec
  module Benchmark
    class << self
      attr_writer :configuration
    end

    # Current configuration
    #
    # @return [RSpec::Benchmark::Configuration]
    #
    # @api public
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Reset current configuration to defaults
    #
    # @return [RSpec::Benchmark::Configuration]
    #
    # @api public
    def self.reset_configuration
      @configuration = Configuration.new
    end

    # Change current configuration
    #
    # @example
    #   RSpec::Benchmark.configure do |config|
    #     config.run_in_subprocess = false
    #   end
    #
    # @api public
    def self.configure
      yield configuration
    end
  end
end
