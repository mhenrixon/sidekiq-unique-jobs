## 1.2.8

* Add `Logger#untagged` to remove previously set logging tags from a block.
* Return result of the block when a block is passed to `Logger#tag`.

## 1.2.7

* Allow passing frozen hashes to `Logger#tag`. Tags passed to this method are now duplicated so the logger maintains it's own copy of the hash.

## 1.2.6

* Fix `Logger#tag` so it only ads to the current block's logger tags instead of the global tags if called inside a `Logger#tag` block.
* Add Logger#remove_tag

## 1.2.5

* Fix logic with recursive reference guard in StructuredFormatter so it only suppresses Enumerable references.
* Add support for bang methods (error!) for setting the log level.

## 1.2.4

* Enhance `ActiveSupport::TaggedLogging` support so code that Lumberjack loggers can be wrapped with a tagged logger.

## 1.2.3

* Fix structured formatter so no-recursive, duplicate references are allowed.

## 1.2.2

* Prevent infinite loops in the structured formatter where objects have backreferences to each other.

## 1.2.1

* Prevent infinite loops where logging a statement triggers the logger.

## 1.2.0

* Enable compatibility with `ActiveSupport::TaggedLogger` by calling `tagged_logger!` on a logger.
* Add `tag_formatter` to logger to specify formatting of tags for output.
* Allow adding and removing classes by name to formatters.
* Allow adding and removing multiple classes in a single call to a formatter.
* Allow using symbols and strings as log level for silencing a logger.
* Ensure flusher thread gets stopped when logger is closed.
* Add writer for logger device attribute.
* Handle passing an array of devices to a multi device.
* Helper method to get a tag with a specified name.
* Add strip formatter to strip whitespace from strings.
* Support non-alpha numeric characters in template variables.
* Add backtrace cleaner to ExceptionFormatter.

## 1.1.1

* Replace Procs in tag values with the value of calling the Proc in log entries.

## 1.1.0

* Change `Lumberjack::Logger` to inherit from ::Logger
* Add support for tags on log messages
* Add global tag context for all loggers
* Add per logger tags and tag contexts
* Reimplement unit of work id as a tag on log entries
* Add support for setting datetime format on log devices
* Performance optimizations
* Add Multi device to output to multiple devices
* Add `DateTimeFormatter`, `IdFormatter`, `ObjectFormatter`, and `StructuredFormatter`
* Add rack `Context` middleware for setting thread global context
* End support for ruby versions < 2.3
* Add support for modules in formatters

## 1.0.13

* Reduce amount of code executed inside a mutex lock when writing to the logger stream.
* Added `:min_roll_check` option to `Lumberjack::Device::RollingLogFile` to reduce file system checks. Default is now to only check if a file needs to be rolled at most once per second.
* Force immutable strings for Ruby versions that support them.

## 1.0.12

* Add support for `ActionDispatch` request id for better Rails compatibility.

## 1.0.11

* Fix Ruby 2.4 deprecation warning on Fixnum (thanks koic).
* Fix gemspec files to be flat array (thanks e2).

## 1.0.10

* Expose option to manually roll log files.
* Minor code cleanup.

## 1.0.9

* Add method so Formatter is compatible with `ActiveSupport` logging extensions.

## 1.0.8

* Fix another internal variable name conflict with `ActiveSupport` logging extensions.

## 1.0.7

* Fix broken formatter attribute method.

## 1.0.6

* Fix internal variable name conflict with `ActiveSupport` logging extensions.

## 1.0.5

* Update docs.
* Remove autoload calls to make thread safe.
* Make compatible with Ruby 2.1.1 Pathname.
* Make compatible with standard library Logger's use of progname as default message.

## 1.0.4

* Add ability to supply a unit of work id for a block instead of having one generated every time.

## 1.0.3

* Change log file output format to binary to avoid encoding warnings.
* Fixed bug in log file rolling that left the file locked.

## 1.0.2

* Remove deprecation warnings under ruby 1.9.3.
* Add more error checking around file rolling.

## 1.0.1

* Writes are no longer buffered by default.
