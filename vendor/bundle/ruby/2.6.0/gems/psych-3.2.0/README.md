# Psych

*   https://github.com/ruby/psych

## Description

Psych is a YAML parser and emitter.  Psych leverages
[libyaml](https://pyyaml.org/wiki/LibYAML) for its YAML parsing and emitting
capabilities.  In addition to wrapping libyaml, Psych also knows how to
serialize and de-serialize most Ruby objects to and from the YAML format.

## Examples

```ruby
# Load YAML in to a Ruby object
Psych.load('--- foo') # => 'foo'

# Emit YAML from a Ruby object
Psych.dump("foo")     # => "--- foo\n...\n"
```

## Dependencies

*   libyaml

## Installation

Psych has been included with MRI since 1.9.2, and is the default YAML parser
in 1.9.3.

If you want a newer gem release of Psych, you can use rubygems:

    gem install psych

In order to use the gem release in your app, and not the stdlib version,
you'll need the following:

    gem 'psych'
    require 'psych'

Or if you use Bundler add this to your `Gemfile`:

    gem 'psych'

JRuby ships with a pure Java implementation of Psych.

If you're on Rubinius, Psych is available in 1.9 mode, please refer to the
Language Modes section of the [Rubinius
README](https://github.com/rubinius/rubinius#readme) for more information on
building and 1.9 mode.

## License

Copyright 2009 Aaron Patterson, et al.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
