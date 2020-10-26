# Change log

## [v0.6.0] - 2020-02-24

### Added
* Add Clock for monotonic time measuring
* Add Stats for arithmetic operations
* Add Perf#ips and Perf#cpu helper methods
* Add IPSResult to capture measurements and stats for iterations
* Add CPUResult to capture measurements and stats for execution

### Changed
* Change to fix Ruby 2.7 warnings
* Change to remove benchmark requirement
* Change to remove #assert_perform_ips & #assert_perform_under
* Change module name from ExecutionTime to Execution
* Change Iteration#run to measure only work elapsed time

### Fixed
* Fix Iteration#run providing no measurements when warmup time exceeds bench time

## [v0.5.0] - 2019-04-21

### Added
* Add :subprocess option To ExecutionTime#run for toggling forking behaviour

### Changed
* Remove ExecutiomTime#linear_range
* Change to relax development dependencies versions

## [v0.4.0] - 2018-09-30

### Changed
* Change ExecutionTime#run :times argument to :repeat
* Change ExecutionTime#run to specify accepted values for :repeat argument
* Change default measurements repeat time to be once

### Fixed
* Change ExecutionTime#run to correctly generate repeats range

## [v0.3.0] - 2018-09-16

### Added
* Add a monotonic time measurement

### Changed
* Change to use Ruby >= 2.0.0
* Change Iteration to be a module and remove state
* Change ExecutionTime to be a module and remove state
* Change ExecutionTime#run to accept :warmup, :times
* Change ExecutionTime & Iteration to measure using monotonic clock

### Fixed
* Fixe ExecutionTime#run to correctly calculate linear range of samples

## [v0.2.1] - 2016-11-03

### Changed
* Remove rescuing marshalling errors

## [v0.2.0] - 2016-11-01

### Added
* Add variance calculation

### Changed
* Change to propagate errors from child process when measuring execution time

### Fixed
* Fix std_dev calculation

## [v0.1.1] - 2016-10-29

### Fixed
* Fix marshalling of time when measuring execution

## [v0.1.0] - 2016-01-25

Initial release

[v0.6.0]: https://github.com/piotrmurach/benchmark-perf/compare/v0.5.0...v0.6.0
[v0.5.0]: https://github.com/piotrmurach/benchmark-perf/compare/v0.4.0...v0.5.0
[v0.4.0]: https://github.com/piotrmurach/benchmark-perf/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/piotrmurach/benchmark-perf/compare/v0.2.1...v0.3.0
[v0.2.1]: https://github.com/piotrmurach/benchmark-perf/compare/v0.2.0...v0.2.1
[v0.2.0]: https://github.com/piotrmurach/benchmark-perf/compare/v0.1.1...v0.2.0
[v0.1.1]: https://github.com/piotrmurach/benchmark-perf/compare/v0.1.0...v0.1.1
[v0.1.0]: https://github.com/piotrmurach/benchmark-perf/compare/v0.1.0
