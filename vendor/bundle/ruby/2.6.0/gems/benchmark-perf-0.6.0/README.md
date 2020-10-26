# Benchmark::Perf

[![Gem Version](https://badge.fury.io/rb/benchmark-perf.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/benchmark-perf.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/wv37qw3x5l9km5kl?svg=true)][appveyor]
[![Code Climate](https://codeclimate.com/github/piotrmurach/benchmark-perf/badges/gpa.svg)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/benchmark-perf/badge.svg?branch=master)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/benchmark-perf.svg?branch=master)][inchpages]

[gem]: http://badge.fury.io/rb/benchmark-perf
[travis]: http://travis-ci.org/piotrmurach/benchmark-perf
[appveyor]: https://ci.appveyor.com/project/piotrmurach/benchmark-perf
[codeclimate]: https://codeclimate.com/github/piotrmurach/benchmark-perf
[coverage]: https://coveralls.io/github/piotrmurach/benchmark-perf?branch=master
[inchpages]: http://inch-ci.org/github/piotrmurach/benchmark-perf

> Measure execution time and iterations per second.

The **Benchmark::Perf** is used by [rspec-benchmark](https://github.com/piotrmurach/rspec-benchmark)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'benchmark-perf'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install benchmark-perf

## Contents

* [1. Usage](#1-usage)
* [2. API](#2-api)
  * [2.1 Execution time](#21-execution-time)
  * [2.2 Iterations](#22-iterations)

## 1. Usage

To see how long it takes to execute a piece of code do:

```ruby
result = Benchmark::Perf.cpu { ... }
```

The result will have information about:

```ruby
result.avg    # => average time in sec
result.stdev  # => standard deviation in sec
result.dt     # => elapsed time in sec
```

Or to see how many iterations per second a piece of code takes do:

```ruby
result = Benchmark::Perf.ips { ... }
```

Then you can query result for:

```ruby
result.avg    # => average ips
result.stdev  # => ips stadard deviation
result.iter   # => number of iterations
result.dt     # => elapsed time
```

## 2. API

### 2.1 Execution time

By default `1` measurement is taken, and before that `1` warmup cycle is run.

If you need to change how many measurements are taken, use the `:repeat` option:

```ruby
result = Benchmark::Perf.cpu(repeat: 10) { ... }
```

Then you can query result for the following information:

```ruby
result.avg    # => average time in sec
result.stdev  # => standard deviation in sec
result.dt     # => elapsed time in sec
```

Increasing the number of measurements will lead to more stable results at the price of longer runtime.

To change how many warmup cycles are done before measuring, use `:warmup` option like so:

```ruby
Benchmark::Perf.cpu(warmup: 2) { ... }
```

If you're interested in having debug output to see exact measurements for each measurement sample use the `:io` option and pass alternative stream:

```ruby
Benchmark::Perf.cpu(io: $stdout) { ... }
```

By default all measurements are done in subprocess to isolate the measured code from other process activities. Sometimes this may have some unintended consequences. For example, when code uses database connections and transactions, this may lead to lost connections. To switch running in subprocess off, use the `:subprocess` option:

```ruby
Benchmark::Perf.cpu(subprocess: false) { ... }
```

Or use the environment variable `RUN_IN_SUBPROCESS` to toggle the behaviour.

### 2.2 Iterations

In order to check how many iterations per second a given code takes do:

```ruby
reuslt = Benchmark::Perf.ips { ... }
```

The result contains measurements that you can query:

```ruby
result.avg    # => average ips
result.stdev  # => ips stadard deviation
result.iter   # => number of iterations
result.dt     # => elapsed time
```

Alternatively, the result can be deconstructed into variables:

```ruby
avg, stdev, iter, dt = *result
```

By default `1` second is spent warming up Ruby VM, you can change this with the `:warmup` option that expects time value in seconds:

```ruby
Benchmark::Perf.ips(warmup: 1.45) { ... } # 1.45 second
```

The measurements are sampled for `2` seconds by default. You can change this value to increase precision using `:time` option:

```ruby
Benchmark::Perf.ips(time: 3.5) { ... } # 3.5 seconds
```

## Contributing

1. Fork it ( https://github.com/piotrmurach/benchmark-perf/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Code of Conduct

Everyone interacting in the Strings project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/piotrmurach/benchmark-perf/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) 2016 Piotr Murach. See LICENSE for further details.
