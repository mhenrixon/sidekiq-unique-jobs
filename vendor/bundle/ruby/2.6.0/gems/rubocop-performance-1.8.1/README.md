# RuboCop Performance

[![Gem Version](https://badge.fury.io/rb/rubocop-performance.svg)](https://badge.fury.io/rb/rubocop-performance)
[![CircleCI](https://circleci.com/gh/rubocop-hq/rubocop-performance.svg?style=svg)](https://circleci.com/gh/rubocop-hq/rubocop-performance)

Performance optimization analysis for your projects, as an extension to [RuboCop](https://github.com/rubocop-hq/rubocop).

## Installation

Just install the `rubocop-performance` gem

```sh
gem install rubocop-performance
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-performance', require: false
```

## Usage

You need to tell RuboCop to load the Performance extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
require: rubocop-performance
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
require:
  - rubocop-other-extension
  - rubocop-performance
```

Now you can run `rubocop` and it will automatically load the RuboCop Performance
cops together with the standard cops.

### Command line

```sh
rubocop --require rubocop-performance
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-performance'
end
```

## The Cops

All cops are located under
[`lib/rubocop/cop/performance`](lib/rubocop/cop/performance), and contain
examples/documentation.

In your `.rubocop.yml`, you may treat the Performance cops just like any other
cop. For example:

```yaml
Performance/Size:
  Exclude:
    - lib/example.rb
```

## Documentation

You can read a lot more about RuboCop Performance in its [official docs](https://docs.rubocop.org/rubocop-performance/).

## Contributing

Checkout the [contribution guidelines](CONTRIBUTING.md).

## License

`rubocop-performance` is MIT licensed. [See the accompanying file](LICENSE.txt) for
the full text.
