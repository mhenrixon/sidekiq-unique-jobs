# SidekiqUniqueJobs [![Build Status](https://travis-ci.org/form26/sidekiq-unique-jobs.png?branch=master)](https://travis-ci.org/form26/sidekiq-unique-jobs)

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

You can also control the expiration length of the uniqueness check. If you want to enforce uniqueness over a longer period than the default of 30 minutes then you can pass the number of seconds you want to use to the sidekiq options:

```ruby
sidekiq_options unique: true, unique_job_expiration: 120 * 60 # 2 hours
```

Requiring the gem in your gemfile should be sufficient to enable unique jobs.

### Finer Control over Uniqueness

Sometimes it is desired to have a finer control over which arguments are used in determining uniqueness of the job, and others may be _transient_. For this use-case, you need to
set `SidekiqUniqueJobs::Config.unique_args_enabled` to true in an initializer, and then defined either `unique_args` method, or a ruby proc.

```ruby
SidekiqUniqueJobs::Config.unique_args_enabled = true
```

The method or the proc can return a modified version of args without the transient arguments included, as shown below:

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options unique: true,
                  unique_args: :unique_args

  def self.unique_args(name, id, options)
    [ name, options[:type] ]
  end

  ...

end

class UniqueJobWithFilterProc
  include Sidekiq::Worker
  sidekiq_options unique: true,
                  unique_args: ->(args) { [ args.first ] }

  ...

end
```

Note that objects passed into workers are converted to JSON *after* running through client middleware. In server
middleware, the JSON is passed directly to the worker `#perform` method. So, you may run into issues where the
arguments are different when enqueuing than they are when performing. Your `unique_args` method may need to
account for this.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

- https://github.com/sax
- https://github.com/eduardosasso
- https://github.com/KensoDev
