# Guard::Bundler

[![Gem Version](https://badge.fury.io/rb/guard-bundler.png)](http://badge.fury.io/rb/guard-bundler) [![Build Status](https://travis-ci.org/guard/guard-bundler.png?branch=master)](https://travis-ci.org/guard/guard-bundler) [![Code Climate](https://codeclimate.com/github/guard/guard-bundler.png)](https://codeclimate.com/github/guard/guard-bundler) [![Coverage Status](https://coveralls.io/repos/guard/guard-bundler/badge.png?branch=master)](https://coveralls.io/r/guard/guard-bundler)

Bundler guard allows to automatically & intelligently install/update bundle when needed.

* Compatible with Bundler 2.1.x
* Tested against the latest Ruby 2.4.x, 2.5.x, 2.6.x, JRuby & Rubinius. See [`.travis-ci.yml`](https://github.com/guard/guard-bundler/blob/master/.travis.yml) for the exact versions.

## Install

Add the gem to your `Gemfile`:

```ruby
group :development do
  gem 'guard-bundler', require: false
end
```

Add the plugin definition to your Guardfile by running this command:

```bash
$ guard init bundler
```

## Usage

Please read the [Guard usage doc](https://github.com/guard/guard#readme)

## Guardfile

Guard::Bundler plugin can be really adapted to all kind of projects.

You can tweak the default Guardfile template (created by `guard init bundler`) if you need to watch files other than the Gemfile or *.gemspec (or if they are in different paths).

Please read the [Guard usage doc](https://github.com/guard/guard#readme) for more information about the Guardfile DSL.

## Development

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/guard-bundler/master/frames).
* Source hosted at [GitHub](https://github.com/guard/guard-bundler).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Update the [README](https://github.com/guard/guard-bundler/blob/master/README.md).
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

## Author

[Yann Lugrin](https://github.com/yannlugrin)

## Maintainer

[Rémy Coutable](https://github.com/rymai) ([@rymai](https://twitter.com/rymai))

## Contributors

[https://github.com/guard/guard-bundler/graphs/contributors](https://github.com/guard/guard-bundler/graphs/contributors)
