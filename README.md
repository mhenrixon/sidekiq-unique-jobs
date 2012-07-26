# SidekiqUniqueJobs

The missing unique jobs for sidekiq

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-unique-jobs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-unique-jobs

## Usage

All that is required is that you specifically set the sidekiq option for *unique* to true like below:

```ruby
sidekiq_options unique: true
```

Requiring the gem in your gemfile should be sufficient to enable unique jobs.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
