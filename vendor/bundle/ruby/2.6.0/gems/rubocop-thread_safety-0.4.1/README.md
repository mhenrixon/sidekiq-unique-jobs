# RuboCop::ThreadSafety

Thread-safety analysis for your projects, as an extension to
[RuboCop](https://github.com/bbatsov/rubocop).

## Installation and Usage

### Installation into an application

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-thread_safety'
```

Install it with Bundler by invoking:

    $ bundle

Add this line to your application's `.rubocop.yml`:

    require: rubocop-thread_safety

Now you can run `rubocop` and it will automatically load the RuboCop
Thread-Safety cops together with the standard cops.

### Scanning an application without adding it to the Gemfile

Install the gem:

    $ gem install rubocop-thread_safety

Scan the application for just thread-safety issues:

    $ rubocop -r rubocop-thread_safety --only ThreadSafety,Style/GlobalVars,Style/ClassVars,Style/MutableConstant

### Configuration

There are some added [configuration options](https://github.com/covermymeds/rubocop-thread_safety/blob/master/config/default.yml) that can be tweaked to modify the behaviour of these thread-safety cops.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/covermymeds/rubocop-thread_safety.

## Copyright

Copyright (c) 2016-2020 CoverMyMeds.
See [LICENSE.txt](LICENSE.txt) for further details.
