# Change log

## [v0.6.0] - 2020-03-09

### Added
* Add Formatter#format_unit for making numbers more readable
* Add :format configuration option

### Changed
* Change TimingMatcher to use new #cpu interface
* Change IterationMatcher to use new #ips interface
* Change IterationMatcher to format iterations with units
* Change gemspec to add metadata, remove test artefacts
* Change benchmark-perf, benchmark-trend & benchmark-malloc versions

### Fixed
* Fix Ruby 2.7 warnings converting hash into keywowrd arguments
* Fix IterationMatcher to stop raising FloatDomainError

## [v0.5.1] - 2019-09-11

### Fixed
* Fix perform_slower_than matcher the at_least & exact comparisons

## [v0.5.0] - 2019-04-21

## Added
* Add benchmark-malloc as a dependency
* Add AllocationMatcher with  #perform_allocation expectation
* Add #perform_log, #perform_exp aliases
* Add threshold matcher for specifying allowed error level when asserting computational complexity
* Add #configure to allow for global configuration of options
* Add :run_in_subprocess, :disable_gc & :samples configuration options

## Changed
* Change to require Ruby >= 2.1.0
* Change ComplexityMatcher to use threshold when verifying the assertion
* Change ComplexityMatcher#in_range to accept full range as an input

## [v0.4.0] - 2018-10-01

### Added
* Add benchmark-trend as a dependency
* Add ComplexityMatcher with #perform_linear, #perform_constant,
  #perform_logarithmic, #perform_power and #perform_exponential expectations
* Add #within and #warmup matchers to IterationMatcher
* Add #warmup matcher to TimingMatcher
* Add #within and #warmup matchers to ComparisonMatcher

### Changed
* Change to require Ruby >= 2.0.0
* Change to update benchmark-perf dependency
* Change IterationMatcher to use new Benchmark::Perf::Iteration api
* Change TimingMatcher to use new Benchmark::Perf::ExecutionTime api
* Change ComparisonMatcher to use new Benchmark::Perf::Iteration api
* Change #and_sample matcher to #sample
* Change TimingMatcher to run only one sample by default

## [v0.3.0] - 2017-02-05

### Added
* Add ComparisonMatcher with #perform_faster_than and #perform_slower_than expectations by Dmitri(@WildDima)
* Add ability to configure timing options for all Matchers such as :warmup & :time

## [v0.2.0] - 2016-11-01

### Changed
* Update dependency for benchmark-perf

## [v0.1.0] - 2016-01-25

Initial release

[v0.6.0]: https://github.com/peter-murach/rspec-benchmark/compare/v0.5.1...v0.6.0
[v0.5.1]: https://github.com/peter-murach/rspec-benchmark/compare/v0.5.0...v0.5.1
[v0.5.0]: https://github.com/peter-murach/rspec-benchmark/compare/v0.4.0...v0.5.0
[v0.4.0]: https://github.com/peter-murach/rspec-benchmark/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/peter-murach/rspec-benchmark/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/peter-murach/rspec-benchmark/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/peter-murach/rspec-benchmark/compare/v0.1.0
