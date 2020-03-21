# frozen_string_literal: true

begin
  require "rspec-benchmark"

  RSpec.configure do |config|
    config.include RSpec::Benchmark::Matchers, perf: true
    config.filter_run_excluding perf: true
  end

  RSpec::Benchmark.configure do |config|
    config.samples = 10
  end
rescue LoadError # rubocop:disable Lint/SuppressedException
  # Do nothing, we don't have test_prof
end
