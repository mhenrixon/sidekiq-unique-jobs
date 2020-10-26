# RSpec::Benchmark

[![Gem Version](https://badge.fury.io/rb/rspec-benchmark.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/rspec-benchmark.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/nxq3dr8xkafmgiv0?svg=true)][appveyor]
[![Code Climate](https://codeclimate.com/github/piotrmurach/rspec-benchmark/badges/gpa.svg)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/rspec-benchmark/badge.svg)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/rspec-benchmark.svg?branch=master)][inchpages]

[gem]: http://badge.fury.io/rb/rspec-benchmark
[travis]: http://travis-ci.org/piotrmurach/rspec-benchmark
[appveyor]: https://ci.appveyor.com/project/piotrmurach/rspec-benchmark
[codeclimate]: https://codeclimate.com/github/piotrmurach/rspec-benchmark
[coverage]: https://coveralls.io/github/piotrmurach/rspec-benchmark
[inchpages]: http://inch-ci.org/github/piotrmurach/rspec-benchmark

> Performance testing matchers for RSpec to set expectations on speed, resources usage and scalability.

**RSpec::Benchmark** is powered by:

* [benchmark-perf](https://github.com/piotrmurach/benchmark-perf) for measuring execution time and iterations per second.
* [benchmark-trend](https://github.com/piotrmurach/benchmark-trend) for estimating computation complexity.
* [benchmark-malloc](https://github.com/piotrmurach/benchmark-malloc) for measuring object and memory allocations.

## Why?

Integration and unit tests ensure that changing code maintains expected functionality. What is not guaranteed is the code changes impact on library performance. It is easy to refactor your way out of fast to slow code.

If you are new to performance testing you may find [Caveats](#5-caveats) section helpful.

## Contents

* [1. Usage](#1-usage)
  * [1.1 Timing](#11-timing)
  * [1.2 Iterations ](#12-iterations)
  * [1.3 Comparison ](#13-comparison)
  * [1.4 Complexity](#14-complexity)
  * [1.5 Allocation](#15-allocation)
* [2. Compounding](#2-compounding)
* [3. Configuration](#3-configuration)
  * [3.1 :disable_gc](#31-disable_gc)
  * [3.2 :run_in_subprocess](#32-run_in_subprocess)
  * [3.3 :samples](#33-samples)
  * [3.4 :format](#34-format)
* [4. Filtering](#4-filtering)
* [5. Caveats](#5-caveats)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec-benchmark'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec-benchmark

## 1. Usage

For matchers to be available globally, in `spec_helper.rb` do:

```ruby
require 'rspec-benchmark'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end
```

This will add the following matchers:

* `perform_under` to see how fast your code runs
* `perform_at_least` to see how many iteration per second your code can do
* `perform_(faster|slower)_than` to compare implementations
* `perform_(constant|linear|logarithmic|power|exponential)` to see how your code scales with time
* `perform_allocation` to limit object and memory allocations

These will help you express expected performance benchmark for an evaluated code.

Alternatively, you can add matchers for particular example:

```ruby
RSpec.describe "Performance testing" do
  include RSpec::Benchmark::Matchers
end
```

Then you're good to start setting performance expectations:

```ruby
expect {
  ...
}.to perform_under(6).ms
```

### 1.1 Timing

The `perform_under` matcher answers the question of how long does it take to perform a given block of code on average. The measurements are taken executing the block of code in a child process for accurate CPU times.

```ruby
expect { ... }.to perform_under(0.01).sec
```

All measurements are assumed to be expressed as seconds. However, you can also provide time in `ms`, `us` and `ns`. The equivalent example in `ms` would be:

```ruby
expect { ... }.to perform_under(10).ms
expect { ... }.to perform_under(10000).us
```

By default the above code will be sampled only once but you can change this by using the `sample` matcher like so:

```ruby
expect { ... }.to perform_under(0.01).sample(10) # repeats measurements 10 times
```

For extra expressiveness you can use `times`:

```ruby
expect { ... }.to perform_under(0.01).sample(10).times
```

You can also use `warmup` matcher that can run your code before the actual samples are taken to reduce erratic execution times.

For example, you can execute code twice before you take 10 actual measurements:

```ruby
expect { ... }.to perform_under(0.01).sec.warmup(2).times.sample(10).times
```

### 1.2 Iterations

The `perform_at_least` matcher allows you to establish performance benchmark of how many iterations per second a given block of code should perform. For example, to expect a given code to perform at least 10K iterations per second do:

```ruby
expect { ... }.to perform_at_least(10000).ips
```

The `ips` part is optional but its usage clarifies the intent.

The performance timing of this matcher can be tweaked using the `within` and `warmup` matchers. These are expressed as seconds.

By default `within` matcher is set to `0.2` second and `warmup` matcher to `0.1` respectively. To change how long measurements are taken, for example, to double the time amount do:

```ruby
expect { ... }.to perform_at_least(10000).within(0.4).warmup(0.2).ips
```

The higher values for `within` and `warmup` the more accurate average readings and more stable tests at the cost of longer test suite overall runtime.

### 1.3 Comparison

The `perform_faster_than` and `perform_slower_than` matchers allow you to test performance of your code compared with other. For example:

```ruby
expect { ... }.to perform_faster_than { ... }
expect { ... }.to perform_slower_than { ... }
```

And if you want to compare how much faster or slower your code is do:

```ruby
expect { ... }.to perform_faster_than { ... }.once
expect { ... }.to perform_faster_than { ... }.twice
expect { ... }.to perform_faster_than { ... }.exactly(5).times
expect { ... }.to perform_faster_than { ... }.at_least(5).times
expect { ... }.to perform_faster_than { ... }.at_most(5).times

expect { ... }.to perform_slower_than { ... }.once
expect { ... }.to perform_slower_than { ... }.twice
expect { ... }.to perform_slower_than { ... }.at_least(5).times
expect { ... }.to perform_slower_than { ... }.at_most(5).times
expect { ... }.to perform_slower_than { ... }.exactly(5).times
```

The `times` part is also optional.

The performance timing of each matcher can be tweaked using the `within` and `warmup` matchers. These are expressed as seconds. By default `within` matcher is set to `0.2` and `warmup` matcher to `0.1` second respectively. To change these matchers values do:

```ruby
expect { ... }.to perform_faster_than.within(0.4).warmup(0.2) { ... }
```

The higher values for `within` and `warmup` the more accurate average readings and more stable tests at the cost of longer test suite overall runtime.

### 1.4 Complexity

The `perform_constant`, `perform_logarithmic`, `perform_linear`, `perform_power` and `perform_exponential` matchers are useful for estimating the asymptotic behaviour of a given block of code. The most basic way to use the expectations to test how your code scales is to use the matchers:

```ruby
expect { ... }.to perform_constant
expect { ... }.to perform_logarithmic/perform_log
expect { ... }.to perform_linear
expect { ... }.to perform_power
expect { ... }.to perform_exponential/perform_exp
```

To test performance in terms of computation complexity you can follow the algorithm:

1. Choose a method to profile.
2. Choose workloads for the method.
3. Describe workloads with input features.
4. Assert the performance in terms of Big-O notation.

Often, before expectation can be set you need to setup some workloads. To create a range of inputs use the `bench_range` helper method.

For example, to create a power range of inputs from `8` to `100_000` do:

```ruby
sizes = bench_range(8, 100_000) # => [8, 64, 512, 4096, 32768, 100000]
```

Then you can use the sizes to create test data, for example to check Ruby's `max` performance create array of number arrays.

```ruby
number_arrays = sizes.map { |n| Array.new(n) { rand(n) } }
```

Using `in_range` matcher you can inform the expectation about the inputs. Each range value together with its index will be yielded as arguments to the evaluated block.

You can either specify the range limits:

```ruby
expect { |n, i|
  number_arrays[i].max
}.to perform_linear.in_range(8, 100_000)
```

Or use previously generated `sizes` array:

```ruby
expect { |n, i|
  number_arrays[i].max
}.to perform_linear.in_range(sizes)
```

This example will generate and yield input `n` and index `i` pairs `[8, 0]`, `[64, 1]`, `[512, 2]`, `[4K, 3]`, `[32K, 4]` and `[100K, 5]` respectively.

By default the range will be generated using ratio of `8`. You can change this using `ratio` matcher:

```ruby
expect { |n, i|
  number_arrays[i].max
}.to perform_linear.in_range(8, 100_000).ratio(2)
```

The performance measurements for a code block are taken only once per range input. You can increase the stability of your performance test by using the `sample` matcher. For example, to repeat measurements 100 times for each range input do:

```ruby
expect { |n, i|
  number_arrays[i].max
}.to perform_linear.in_range(8, 100_000).ratio(2).sample(100).times
```

The overall quality of the performance trend is assessed using a threshold value where `0` means a poor fit and `1` a perfect fit. By default this value is configured to `0.9` as a 'good enough' threshold. To change this use `threshold` matcher:

```ruby
expect { |n, i|
  number_arrays[i].max
}.to perform_linear.in_range(8, 100_000).threshold(0.95)
```

### 1.5 Allocation

The `perform_allocation` matcher checks how much memory or objects have been allocated during a piece of Ruby code execution.

By default the matcher verifies the number of object allocations. The specified number serves as the _upper limit_ of allocations, so your tests won't become brittle as different Ruby versions change internally how many objects are allocated for some operations.

Note that you can also check for memory allocation using the `bytes` matcher.

To check number of objects allocated do:

```ruby
expect {
  ["foo", "bar", "baz"].sort[1]
}.to perform_allocation(3)
```

You can also be more granular with your object allocations and specify which object types you're interested in:

```ruby
expect {
  _a = [Object.new]
  _b = {Object.new => 'foo'}
}.to perform_allocation({Array => 1, Object => 2}).objects
```

And you can also check how many objects are left when expectation finishes to ensure that `GC` is able to collect them.

```ruby
expect {
  ["foo", "bar", "baz"].sort[1]
}.to perform_allocation(3).and_retain(3)
```

You can also set expectations on the memory size. In this case the memory size will serve as upper limit for the expectation:

```ruby
expect {
  _a = [Object.new]
  _b = {Object.new => 'foo'}
}.to perform_allocation({Array => 40, Hash => 384, Object => 80}).bytes
```

## 2. Compounding

All the matchers can be used in compound expressions via `and/or`. For example, if you wish to check if a computation performs under certain time boundary and iterates at least a given number do:

```ruby
expect {
  ...
}.to perform_under(6).ms and perform_at_least(10000).ips
```

## 3. Configuration

By default the following configuration is used:

```ruby
RSpec::Benchmark.configure do |config|
  config.run_in_subprocess = false
  config.disable_gc = false
end
```

### 3.1. `:disable_gc`

By default all tests are run with `GC` enabled. We want to measure real performance or Ruby code. However, disabling `GC` may lead to much quicker test execution. You can change this setting:

```ruby
RSpec::Benchmark.configure do |config|
  config.disable_gc = true
end
```

### 3.2 `:run_in_subprocess`

The `perform_under` matcher can run all the measurements in the subprocess. This will increase isolation from other processes activity. However, the `rspec-rails` gem runs all tests in transactions. Unfortunately, when running tests in child process, database connections are used from connection pool and no data can be accessed. This is only a problem when running specs in Rails. Any other Ruby project can run specs using subprocesses. To enable this behaviour do:

```ruby
RSpec::Benchmark.configure do |config|
  config.run_in_subprocess = true
end
```

### 3.3 `:samples`

The `perform_under` and computational complexity matchers allow to specify how many times to repeat measurements. You configure it globally for all matchers using the `:samples` option which defaults to `1`:

```ruby
RSpec::Benchmark.configure do |config|
  config.samples = 10
end
```

### 3.4 `:format`

The `perform_at_least` matcher uses the `:format` option to format the number of iterations when a failure message gets displayed. By default, the `:human` values is used to make numbers more readable. For example, the `12300 i/s` gets turned into `12.3k i/s`. If you rather have an exact numbers presented do:

```ruby
RSpec::Benchmark.configure do |config|
  config.format = :raw
end
```

## 4. Filtering

Usually performance tests are best left for CI or occasional runs that do not affect TDD/BDD cycle.

To achieve isolation you can use RSpec filters to exclude performance tests from regular runs. For example, in `spec_helper`:

```ruby
RSpec.config do |config|
  config.filter_run_excluding perf: true
end
```

And then in your example group do:

```ruby
RSpec.describe ..., :perf do
  ...
end
```

Then you can run groups or examples tagged with `perf`:

```
rspec --tag perf
```

Another option is to simply isolate the performance specs in separate directory such as `spec/performance/...` and add custom rake task to run them.

## 5. Caveats

When writing performance tests things to be mindful are:

+ The tests may **potentially be flaky** thus its best to use sensible boundaries:
  - **too strict** boundaries may cause false positives, making tests fail
  - **too relaxed** boundaries may also lead to false positives missing actual performance regressions
+ Generally performance tests will be **slow**, but you may try to avoid _unnecessarily_ slow tests by choosing smaller maximum value for sampling

If you have any other observations please share them!

## Contributing

1. Fork it ( https://github.com/piotrmurach/rspec-benchmark/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Code of Conduct

Everyone interacting in the Strings project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/piotrmurach/rspec-benchmark/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) 2016 Piotr Murach. See LICENSE for further details.
