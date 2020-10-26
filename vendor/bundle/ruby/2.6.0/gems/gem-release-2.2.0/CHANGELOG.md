# Changelog

## v2.2.0 - 2020-10-12

### Added

- Allow version bump to specific prerelease version number  
  (PR: https://github.com/svenfuchs/gem-release/pull/97)

## v2.1.1 - 2019-10-28

### Fixed

- Fix error when custom message provided for `gem bump`  
  (PR: https://github.com/svenfuchs/gem-release/pull/92)

## v2.1.0 - 2019-10-17

### Added

- Add gem release --github  
  (PR: https://github.com/svenfuchs/gem-release/pull/73)

## v2.0.4 - 2019-10-10

### Fixed

- Make default "stage delimiter" to be dot instead of dash  
  (PR: https://github.com/svenfuchs/gem-release/pull/87)

## v2.0.3 - 2019-07-04

### Fixed

- Fix `gem-release` Heredoc for Ruby 2.2  
  (PR: https://github.com/svenfuchs/gem-release/pull/82)
- Partially Fix "gem bump tags the wrong version"  
  (PR: https://github.com/svenfuchs/gem-release/pull/83)

## v2.0.2 - 2019-06-27

### Fixed

- Fix typo triggered by `gem bootstrap`  
  (PR: https://github.com/svenfuchs/gem-release/pull/78)

## v2.0.1 - 2018-06-17

`2.0.0` is yanked due to bad release  
So this version is the real `2.0.0`  

## v2.0.0

This is a major rewrite, 7 years after the initial implementation.

### Major changes

* Consistent config format, using config files, environment variables, and command line options
* Custom template groups for `gem bootstrap`
* Complete help output in `gem [command] --help`
* Consistent behaviour in multi-gem scenarios (see the [README](https://github.com/svenfuchs/gem-release/blob/master/README.md#scenarios))
* Consistent command line option defaults across commands when invoked with a
  shortcut, e.g. `gem bump --release --tag` vs `gem release --tag`
* Colorized, more consistently formatted output
* Parse friendly output on all commands when not on a tty (e.g. `gem bump --pretend --no-commit | awk '{ print $4 }')

### Other changes

* Fix misleading success message when `gem push` fails
* Release and tag now fail if there are uncommitted changes
* Add `--message` and `--skip-ci` to `gem bump` in order to customize the commit message
* Add `--branch` to `gem bump` in order to switch to a new branch
* Add `--sign` to `gem bump` and `gem tag` in order to GPG sign commits and tags
* Add `--no-color` to all commands
* Support version files of gems with an `\*\_rb` suffix
* Add `--bin` to `gem gemspec`, add executables to gemspec
* Add `--bin` to `gem bootstrap`, create executables
