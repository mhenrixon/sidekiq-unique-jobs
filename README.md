# SidekiqUniqueJobs [![Build Status](https://travis-ci.org/mhenrixon/sidekiq-unique-jobs.png?branch=master)](https://travis-ci.org/mhenrixon/sidekiq-unique-jobs) [![Code Climate](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs.png)](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs)

The missing unique jobs for sidekiq

## Requirements

See https://github.com/mperham/sidekiq#requirements for what is required. Starting from 3.0.13 only sidekiq 3 is supported and support for MRI 1.9 is dropped (it might work but won't be worked on)

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

For jobs scheduled in the future it is possible to set for how long the job
should be unique. The job will be unique for the number of seconds configured (default 30 minutes)
or until the job has been completed. Thus, the job will be unique for the shorter of the two.  Note that Sidekiq versions before 3.0 will remove job keys after an hour, which means jobs can remain unique for at most an hour.

*If you want the unique job to stick around even after it has been successfully
processed then just set the unique_unlock_order to anything except `:before_yield` or `:after_yield` (`unique_unlock_order = :never`)

You can also control the expiration length of the uniqueness check. If you want to enforce uniqueness over a longer period than the default of 30 minutes then you can pass the number of seconds you want to use to the sidekiq options:

```ruby
sidekiq_options unique: true, unique_job_expiration: 120 * 60 # 2 hours
```

Requiring the gem in your gemfile should be sufficient to enable unique jobs.

### Usage with ActiveJob

```ruby
Sidekiq.default_worker_options = {
   'unique' => true,
   'unique_args' => proc do |args|
     [args.first.except('job_id')]
   end
}
SidekiqUniqueJobs.config.unique_args_enabled = true
```


### Finer Control over Uniqueness

Sometimes it is desired to have a finer control over which arguments are used in determining uniqueness of the job, and others may be _transient_. For this use-case, you need to set `SidekiqUniqueJobs.config.unique_args_enabled` to true in an initializer, and then defined either `unique_args` method, or a ruby proc.

The unique_args method need to return an array of values to use for uniqueness check.

```ruby
SidekiqUniqueJobs.config.unique_args_enabled = true
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

Note that objects passed into workers are converted to JSON *after* running through client middleware. In server middleware, the JSON is passed directly to the worker `#perform` method. So, you may run into issues where the arguments are different when enqueuing than they are when performing. Your `unique_args` method may need to account for this.

### Unlock Ordering

By default the server middleware will release the worker lock after yielding to the next middleware or worker. Alternatively, this can be changed by passing the `unique_unlock_order` option:

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options unique: true,
                  unique_unlock_order: :before_yield

  ...

end
```

### Unique Storage Method

Starting from sidekiq-unique-jobs 3.0.14 we will use the `set` method in a way that has been available since redis 2.6.12. If you are on an older redis version you will have to change a config value like below.

```ruby
SidekiqUniqueJobs.config.unique_storage_method = :old
```

That should allow you to keep using redis in the old fashion way. See #89 for mor information.


### Logging

To see logging in sidekiq when duplicate payload has been filtered out you can enable on a per worker basis using the sidekiq options.  The default value is false

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options unique: true,
                  log_duplicate_payload: true

  ...

end
```

### Testing

SidekiqUniqueJobs uses mock_redis for inline testing. Due to complaints about having that as a runtime dependency it was made a development dependency so if you are relying on inline testing you will have to add `gem 'mock_redis'` to your Gemfile.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

- https://github.com/salrepe
- https://github.com/rickenharp
- https://github.com/sax
- https://github.com/eduardosasso
- https://github.com/KensoDev
- https://github.com/adstage-david
- https://github.com/jprincipe
- https://github.com/crberube
- https://github.com/simonoff
