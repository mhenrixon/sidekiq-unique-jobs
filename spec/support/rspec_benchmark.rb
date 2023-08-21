# frozen_string_literal: true

begin
  require "rspec-benchmark"

  RSpec.configure do |config|
    config.include RSpec::Benchmark::Matchers, perf: true
    config.filter_run_excluding perf: true
  end

  RSpec::Benchmark.configure do |config|
    config.run_in_subprocess = false
    config.disable_gc = false
    config.samples = 10
  end
rescue LoadError
  # Do nothing, we don't have test_prof
end
