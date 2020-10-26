# Benchmark::Trend

[![Gem Version](https://badge.fury.io/rb/benchmark-trend.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/benchmark-trend.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/798apneaa8ixg5dk?svg=true)][appveyor]
[![Maintainability](https://api.codeclimate.com/v1/badges/782faa4a8a4662c86792/maintainability)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/benchmark-trend/badge.svg?branch=master)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/benchmark-trend.svg?branch=master)][inchpages]

[gem]: http://badge.fury.io/rb/benchmark-trend
[travis]: http://travis-ci.org/piotrmurach/benchmark-trend
[appveyor]: https://ci.appveyor.com/project/piotrmurach/benchmark-trend
[codeclimate]: https://codeclimate.com/github/piotrmurach/benchmark-trend/maintainability
[coverage]: https://coveralls.io/github/piotrmurach/benchmark-trend?branch=master
[inchpages]: http://inch-ci.org/github/piotrmurach/benchmark-trend

> Measure performance trends of Ruby code based on the input size distribution.

**Benchmark::Trend** will help you estimate the computational complexity of Ruby code by running it on inputs increasing in size, measuring their execution times, and then fitting these observations into a model that best predicts how a given Ruby code will scale as a function of growing workload.

## Why?

Tests provide safety net that ensures your code works correctly. What you don't know is how fast your code is! How does it scale with different input sizes? Your code may have computational complexity that doesn't scale with large workloads. It would be good to know before your application goes into production, wouldn't it?

**Benchmark::Trend** will allow you to uncover performance bugs or confirm that a Ruby code performance scales as expected.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'benchmark-trend'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install benchmark-trend

## Contents

* [1. Usage](#1-usage)
* [2. API](#2-api)
  * [2.1 range](#21-range)
  * [2.2 infer_trend](#22-infer_trend)
    * [2.2.1 repeat](#221-repeat)
  * [2.3 fit](#23-fit)
  * [2.4 fit_at](#24-fit_at)
* [3. Examples](#3-examples)
  * [3.1 Ruby array max](#31-ruby-array-max)

## 1. Usage

Let's assume we would like to find out behaviour of a Fibonacci algorithm:

```ruby
def fibonacci(n)
  n < 2 ? n : fibonacci(n - 1) + fibonacci(n - 2)
end
```

To measure the actual complexity of above function, we will use `infer_trend` method and pass it as a first argument an array of integer sizes and a block to execute the method:

```ruby
numbers = Benchmark::Trend.range(1, 28, ratio: 2)

trend, trends = Benchmark::Trend.infer_trend(numbers) do |n, i|
  fibonacci(n)
end
```

The return type will provide a best trend name:

```ruby
print trend
# => exponential
```

and a Hash of all the trend data:

```ruby
print trends
# =>
# {:exponential=>
#   {:trend=>"1.38 * 0.00^x",
#    :slope=>1.382889711685203,
#    :intercept=>3.822775903539121e-06,
#    :residual=>0.9052392775178072},
#  :power=>
#   {:trend=>"0.00 * x^2.11",
#    :slope=>2.4911044372815657e-06,
#    :intercept=>2.1138475434240918,
#    :residual=>0.5623418036957115},
#  :linear=>
#   {:trend=>"0.00 + -0.01*x",
#    :slope=>0.0028434594496586007,
#    :intercept=>-0.01370769842204958,
#    :residual=>0.7290365425188893},
#  :logarithmic=>
#   {:trend=>"0.02 + -0.02*ln(x)",
#    :slope=>0.01738674709454521,
#    :intercept=>-0.015489004560847924,
#    :residual=>0.3982368125757882}}
```

You can see information for the best trend by passing name into trends hash:

```ruby
print trends[trend]
# =>
# {:trend=>"1.38 * 0.00^x",
#  :slope=>1.382889711685203,
#  :intercept=>3.822775903539121e-06,
#  :residual=>0.9052392775178072},
```

## 2. API

### 2.1 range

To generate a range of values for testing code fitness use the `range` method. It will generate a geometric sequence of numbers, where intermediate values are powers of range multiplier, by default 8:

```ruby
Benchmark::Trend.range(8, 8 << 10)
# => [8, 64, 512, 4096, 8192]
```

You can change the default sequence power by using `:ratio` keyword:

```ruby
Benchmark::Trend.range(8, 8 << 10, ratio: 2)
# => [8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]
```

### 2.2 infer_trend

To calculate an asymptotic behaviour of Ruby code by inferring its computational complexity use `infer_trend`. This method takes as an argument an array of inputs which can be generated using [range](#21-range). The code to measure needs to be provided inside a block. Two parameters are always yielded to a block, first, the actual data input and second the current index matching the input.

For example, let's assume you would like to find out asymptotic behaviour of a Fibonacci algorithm:

```ruby
def fibonacci(n)
  n < 2 ? n : fibonacci(n - 1) + fibonacci(n - 2)
end
```

You could start by generating a range of inputs in powers of 2:

```ruby
numbers = Benchmark::Trend.range(1, 32, ratio: 2)
# => [1, 2, 4, 8, 16, 32]
```

Then measure the performance of the Fibonacci algorithm for each of the data points and fit the observations into a model to predict behaviour as a function of input size:

```ruby
trend, trends = Benchmark::Trend.infer_trend(numbers) do |n, i|
  fibonacci(n)
end
```

The return includes the best fit name:

```ruby
print trend
# => exponential
```

And a Hash of all measurements:

```ruby
print trends
# =>
# {:exponential=>
#   {:trend=>"1.38 * 0.00^x",
#    :slope=>1.382889711685203,
#    :intercept=>3.822775903539121e-06,
#    :residual=>0.9052392775178072},
#  :power=>
#   {:trend=>"0.00 * x^2.11",
#    :slope=>2.4911044372815657e-06,
#    :intercept=>2.1138475434240918,
#    :residual=>0.5623418036957115},
#  :linear=>
#   {:trend=>"0.00 + -0.01*x",
#    :slope=>0.0028434594496586007,
#    :intercept=>-0.01370769842204958,
#    :residual=>0.7290365425188893},
#  :logarithmic=>
#   {:trend=>"0.02 + -0.02*ln(x)",
#    :slope=>0.01738674709454521,
#    :intercept=>-0.015489004560847924,
#    :residual=>0.3982368125757882}}
```

In order to retrieve trend data for the best fit do:

```ruby
print trends[trend]
# =>
# {:trend=>"1.38 * 0.00^x",
#  :slope=>1.382889711685203,
#  :intercept=>3.822775903539121e-06,
#  :residual=>0.9052392775178072}
```

### 2.2.1 repeat

To increase stability of you tests consider repeating all time execution measurements using `:repeat` keyword.

Start by generating a range of inputs for your algorithm:

```ruby
numbers = Benchmark::Trend.range(1, 32, ratio: 2)
# => [1, 2, 4, 8, 16, 32]
```

and then run your algorithm for each input repeating measurements `100` times:

```ruby
Benchmark::Trend.infer_trend(numbers, repeat: 100) { |n, i| ... }
```

### 2.3 fit

Use `fit` method if you wish to fit arbitrary data into a model with a slope and intercept parameters that minimize the error.

For example, given a set of data points that exhibit linear behaviour:

```ruby
xs = [1, 2, 3, 4, 5]
ys = xs.map { |x| 3.0 * x + 1.0 }
```

Fit the data into a model:

```ruby
slope, intercept, error = Benchmark::Trend.fit(xs, ys)
```

And printing the values we get confirmation of the linear behaviour of the data points:

```ruby
print slope
# => 3.0
print intercept
# => 1.0
print error
# => 1.0
```

### 2.4 fit_at

If you are interested how a model scales for a given input use `fit_at`. This method expects that there is a fit model generated using [infer_trend](#22-infer_trend).

For example, measuring Fibonacci recursive algorithm:

```ruby
numbers = Benchmark::Trend.range(1, 28, ratio: 2)
trend, trends = Benchmark::Trend.infer_trend(numbers) do |n, i|
  fibonacci(n)
end
```

We get the following results:

```ruby
trends[trend]
# =>
# {:trend=>"1.38 * 0.00^x",
#  :slope=>1.382889711685203,
#  :intercept=>3.822775903539121e-06,
#  :residual=>0.9052392775178072}
```

And checking model at input of `50`:

```ruby
Benchamrk::Trend.fit_at(trend, n: 50, slope: trends[trend][:slope], intercept: trends[trend][:intercept])
# => 41.8558455915123
```

We can see that Fibonacci with just a number 50 will take around 42 seconds to get the result!

How about Fibonacci with 100 as an input?

```ruby
Benchamrk::Trend.fit_at(trend, n: 100, slope: trends[trend][:slope], intercept: trends[trend][:intercept])
# => 458282633.9777338
```

This means Fibonacci recursive algorithm will take about 1.45 year to complete!

## 3. Examples

### 3.1 Ruby array max

Suppose you wish to find an asymptotic behaviour of Ruby built Array `max` method.

You could start with generating a [range](#21-range) of inputs:

```ruby
array_sizes = Benchmark::Trend.range(1, 100_000)
# => [1, 8, 64, 512, 4096, 32768, 100000]
```

Next, based on the generated ranges create arrays containing randomly generated integers:

```ruby
number_arrays = array_sizes.map { |n| Array.new(n) { rand(n) } }
```

Then feed this information to infer a trend:

```ruby
trend, trends = Benchmark::Trend.infer_trend(array_sizes) do |n, i|
  number_arrays[i].max
end
```

Unsurprisingly, we discover that Ruby's `max` call scales linearily with the input size:

```ruby
print trend
# => linear
```

We can also see from the residual value that this is a near perfect fit:

```ruby
print trends[trend]
# =>
# {:trend=>"0.00 + 0.00*x",
#  :slope=>5.873536409841244e-09,
#  :intercept=>3.028647045635842e-05,
#  :residual=>0.9986764704492359}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/benchmark-trend. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Benchmark::Trend project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/piotrmurach/benchmark-trend/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) 2018 Piotr Murach. See LICENSE for further details.
