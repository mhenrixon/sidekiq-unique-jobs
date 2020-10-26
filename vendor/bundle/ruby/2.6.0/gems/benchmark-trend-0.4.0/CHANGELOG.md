# Change log

## [v0.4.0] - 2020-03-07

### Added
* Add Clock for monotonic time measuring

### Changed
* Change to remove benchmark requirement
* Change gemspec to add metadata, remove test artefacts

## [v0.3.0] - 2019-04-21

### Changed
* Change to require Ruby >= 2.0.0
* Change to relax development dependencies

## [v0.2.0] - 2018-09-30

### Added
* Add ability to measure monotonic time
* Add ability to repeat measurements to increase stability of execution times

### Changed
* Change to prefer simpler complexity for similar measurements
* Change to use monotonic clock
* Change to differentiate linear vs logarithmic complexity for small values
* Change to differentiate linear vs constant complexity for small values

## Fixed
* Fix fit_power to correctly calculate slope and intercept

## [v0.1.0] - 2018-09-08

* Initial implementation and release

[v0.4.0]: https://github.com/piotrmurach/benchmark-trend/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/piotrmurach/benchmark-trend/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/piotrmurach/benchmark-trend/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/piotrmurach/benchmark-trend/compare/v0.1.0
