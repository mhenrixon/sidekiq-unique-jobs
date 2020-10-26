# simplecov-oj

JSON formatter for the ruby 2.5+ code coverage gem SimpleCov

## Usage

1. Add simplecov-oj to your `Gemfile` and `bundle install`:

```ruby
gem 'simplecov-oj', require: false, group: :test
```

2. Require simplecov-oj and set it up as SimpleCov's formatter:

```ruby
require 'simplecov-oj'
SimpleCov.formatter = SimpleCov::Formatter::OjFormatter
```

## Result

Generated JSON can be found in coverage/coverage.json

The format you can expect is:
```json
{
    "timestamp": 1348489587,
    "command_name": "RSpec",
    "files": [
        {
            "filename": "/home/user/rails/environment.rb",
            "covered_percent": 50.0,
            "coverage": [
                null,
                1,
                null,
                null,
                1
            ],
            "covered_strength": 0.50,
            "covered_lines": 2,
            "lines_of_code": 4
        },
        ...
    ],
    "metrics": {
          "covered_percent": 81.70731707317073,
          "covered_strength": 0.8170731707317073,
          "covered_lines": 67,
          "total_lines": 82
    }
}
```

## Making Contributions

If you want to contribute, please:

  * Fork the project.
  * Make your feature addition or bug fix.
  * Add tests for it. This is important so I don't break it in a future version unintentionally.
  * Send me a pull request on Github.
  * Check that travis build passes for your pull request.


## Copyright

Copyright (c) 2020 Mikael Henriksson. See LICENSE for details.
