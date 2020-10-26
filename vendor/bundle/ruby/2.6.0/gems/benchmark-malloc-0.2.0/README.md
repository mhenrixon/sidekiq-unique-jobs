# Benchmark::Malloc

[![Gem Version](https://badge.fury.io/rb/benchmark-malloc.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/benchmark-malloc.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/cp102e33c2a7fx83?svg=true)][appveyor]
[![Maintainability](https://api.codeclimate.com/v1/badges/d8fbd4a0423fd78d8bee/maintainability)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/benchmark-malloc/badge.svg?branch=master)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/benchmark-malloc.svg?branch=master)][inchpages]

[gem]: http://badge.fury.io/rb/benchmark-malloc
[travis]: http://travis-ci.org/piotrmurach/benchmark-malloc
[appveyor]: https://ci.appveyor.com/project/piotrmurach/benchmark-malloc
[codeclimate]: https://codeclimate.com/github/piotrmurach/benchmark-malloc/maintainability
[coverage]: https://coveralls.io/github/piotrmurach/benchmark-malloc?branch=master
[inchpages]: http://inch-ci.org/github/piotrmurach/benchmark-malloc

> Trace memory allocations and collect stats.

The **Benchmark::Malloc** is used by [rspec-benchmark](https://github.com/piotrmurach/rspec-benchmark)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'benchmark-malloc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install benchmark-malloc

## Usage

```ruby
bench_malloc = Benchmark::Malloc.new

stats = bench_malloc.run { %w[foo bar baz].sort[1] }

stats.allocated.total_objects # => 3

stats.allocated.total_memory # => 120
```

## API

### start & stop

You can manually begin tracing memory allocations with the `start` method:

```ruby
malloc = Benchmark::Malloc.new
malloc.start
```

Any Ruby code after the `start` invocation will count towards the stats:

```ruby
%w[foo bar baz].sort[1]
```

Finally, to finish tracing call the `stop` method:

```ruby
malloc.stop
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/piotrmurach/benchmark-malloc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Benchmark::Malloc project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/piotrmurach/benchmark-malloc/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) 2019 Piotr Murach. See LICENSE for further details.
