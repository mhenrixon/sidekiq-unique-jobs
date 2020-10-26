[![Gem Version](http://img.shields.io/gem/v/guard-reek.svg)](http://badge.fury.io/rb/guard-reek)
[![Build Status](https://travis-ci.org/grantspeelman/guard-reek.svg?branch=master)](https://travis-ci.org/grantspeelman/guard-reek)

# guard-reek

**guard-reek** allows you to automatically detect code smells with [Reek](https://github.com/troessner/reek) when files are modified.

## Installation

Please make sure to have [Guard](https://github.com/guard/guard) installed before continue.

Add `guard-reek` to your `Gemfile`:

```ruby
group :development do
  gem 'guard-reek'
end
```

and then execute:

```sh
$ bundle install
```

or install it yourself as:

```sh
$ gem install guard-reek
```

Add the default Guard::Reek definition to your `Guardfile` by running:

```sh
$ guard init reek
```

## Usage

Please read the [Guard usage documentation](https://github.com/guard/guard#readme).

## Options

You can pass some options in `Guardfile` like the following example:

```ruby
guard :reek, all_on_start: false, run_all: false, cli: '--single-line --no-wiki-links' do
  # ...
end
```

### Available Options

```
all_on_start: true     # Check all files at Guard startup.
                       #   default: true
all: 'app lib spec'    # What to run when running all
                       # An array or string is acceptable.
                       #   default: *
cli: '--single-line'   # Pass arbitrary reek CLI arguments.
                       # An array or string is acceptable.
                       #   default: nil
run_all: true          # Check all files on "Enter"
                       #   default: true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
