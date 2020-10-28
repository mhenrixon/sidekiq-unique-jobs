This gem is used to avoid having to duplicate my .rubocop configuration in all my open source projects.

It depends on the following rubocop files

```ruby
gem 'rubocop', '~> 0.79'
gem 'rubocop-performance', '~> 1.5'
gem 'rubocop-rake', '~> 0.5'
gem 'rubocop-rspec', '~> 1.37'
gem 'rubocop-thread_safety', '~> 0.3'
gem 'rubocop-require_tools', '~> 0.1'
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-mhenrixon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rubocop-mhenrixon

## Usage

At the top of your `.rubocop.yml` add the following

```yaml
inherit_gem:
  rubocop-mhenrixon:
    - config/default.yml
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rubocop-mhenrixon. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rubocop::Mhenrixon project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rubocop-mhenrixon/blob/master/CODE_OF_CONDUCT.md).
