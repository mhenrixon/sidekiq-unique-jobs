# SidekiqUniqueJobs [![Join the chat at https://gitter.im/mhenrixon/sidekiq-unique-jobs](https://badges.gitter.im/mhenrixon/sidekiq-unique-jobs.svg)](https://gitter.im/mhenrixon/sidekiq-unique-jobs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://travis-ci.org/mhenrixon/sidekiq-unique-jobs.png?branch=master)](https://travis-ci.org/mhenrixon/sidekiq-unique-jobs) [![Code Climate](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs.png)](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs) [![Test Coverage](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/badges/coverage.svg)](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/coverage)

The missing unique jobs for sidekiq

## Requirements

See https://github.com/mperham/sidekiq#requirements for what is required. Starting from 5.0.0 only sidekiq >= 4 is supported and support for MRI <=  2.1 is dropped.

### Version 4 Upgrade instructions

Version 5 requires redis >= 3

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-unique-jobs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-unique-jobs

## Locking

Sidekiq consists of a client and a server. The client is responsible for pushing jobs to the queue and the worker is responsible for popping jobs from the queue. Most of the uniqueness is handled when the client is pushing jobs to the queue. The client checks if it is allowed to put a job on the queue. 
This is probably the most common way of locking.

The server can also lock a job. It does so by creating a lock when it is executing and removing the lock after it is done executing.

### Options

#### Lock Expiration

This is the a number in seconds that the lock should be considered unique for. By default the lock doesn't expire at all. 

If you want to experiment with various expirations please provide the following argument: 

```ruby
sidekiq_options lock_expiration: (2 * 60) # 2 minutes
```

#### Lock Timeout

This is the timeout (how long to wait) for creating the lock. By default we don't use a timeout so we won't wait for the lock to be created. If you want it is possible to set this like below.

```ruby
sidekiq_options lock_timeout: 5 # 5 seconds
```

#### Lock Resources

This allows us to perform multiple locks for a unique key. 

```ruby
sidekiq_options lock_resources: 2 # Use 2 locks
```

#### 

### While Executing

With this lock type it is possible to put any number of these jobs on the queue at but as the server pops the job from the queue it will create a lock and then wait until other locks are done processing. It *looks* like multiple jobs are running at the same time but in fact the second job will only be waiting for the first job to finish.

```ruby
sidekiq_options unique: :while_executing
```

There is an example of this to try it out in the `rails_example` application. Run `foreman start` in the root of the directory and open the url: `localhost:5000/work/duplicate_while_executing`.

In the console you should see something like:

```
0:32:24 worker.1 | 2017-04-23T08:32:24.955Z 84404 TID-ougq4thko WhileExecutingWorker JID-400ec51c9523f41cd4a35058 INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.956Z 84404 TID-ougq8csew WhileExecutingWorker JID-8d6d9168368eedaed7f75763 INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.957Z 84404 TID-ougq8crt8 WhileExecutingWorker JID-affcd079094c9b26e8b9ba60 INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.959Z 84404 TID-ougq8cs8s WhileExecutingWorker JID-9e197460c067b22eb1b5d07f INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.959Z 84404 TID-ougq4thko WhileExecutingWorker JID-400ec51c9523f41cd4a35058 WhileExecutingWorker INFO: perform(1, 2)
10:32:34 worker.1 | 2017-04-23T08:32:34.964Z 84404 TID-ougq4thko WhileExecutingWorker JID-400ec51c9523f41cd4a35058 INFO: done: 10.009 sec
10:32:34 worker.1 | 2017-04-23T08:32:34.965Z 84404 TID-ougq8csew WhileExecutingWorker JID-8d6d9168368eedaed7f75763 WhileExecutingWorker INFO: perform(1, 2)
10:32:44 worker.1 | 2017-04-23T08:32:44.965Z 84404 TID-ougq8crt8 WhileExecutingWorker JID-affcd079094c9b26e8b9ba60 WhileExecutingWorker INFO: perform(1, 2)
10:32:44 worker.1 | 2017-04-23T08:32:44.965Z 84404 TID-ougq8csew WhileExecutingWorker JID-8d6d9168368eedaed7f75763 INFO: done: 20.009 sec
10:32:54 worker.1 | 2017-04-23T08:32:54.970Z 84404 TID-ougq8cs8s WhileExecutingWorker JID-9e197460c067b22eb1b5d07f WhileExecutingWorker INFO: perform(1, 2)
10:32:54 worker.1 | 2017-04-23T08:32:54.969Z 84404 TID-ougq8crt8 WhileExecutingWorker JID-affcd079094c9b26e8b9ba60 INFO: done: 30.012 sec
10:33:04 worker.1 | 2017-04-23T08:33:04.973Z 84404 TID-ougq8cs8s WhileExecutingWorker JID-9e197460c067b22eb1b5d07f INFO: done: 40.014 sec
```

### Until Executing

These jobs will be unique until they have been taken off the queue by the sidekiq server. Then new jobs can be pushed to the queue again. 

**Note:** For slow running jobs this is probably not the best choice as another slow running job with the same arguments could potentially be started. There is nothing that prevents simultaneous jobs to be running.

```ruby
sidekiq_options unique: :until_executing
```

### Until Executed

When these jobs are pushed to the queue by the sidekiq client a key is created that won't be removed until the sidekiq server successfully executed the job. 

**Note:** Uniqueness is kept from when the job is pushed to the queue until after it is processed.

```ruby
sidekiq_options unique: :until_executed
```

### Until Timeout

These jobs will be unique until they timeout. In the meantime no further jobs will be created with the given unique arguments.

```ruby
sidekiq_options unique: :until_timeout
```

### Unique Until And While Executing

First a unique key is created when the Sidekiq client pushes the job to the queue. No job with the same arguments can be pushed to the queue. Then as the server pops the job off of the queue the original lock is unlocked and the server then creates a 

```ruby
sidekiq_options unique: :until_and_while_executing
```

### Uniqueness Scope

- Queue specific locks
- Across all queues - [spec/jobs/unique_on_all_queues_job.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/jobs/unique_on_all_queues_job.rb)
- Across all workers - [spec/jobs/unique_across_workers_job.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/jobs/unique_across_workers_job.rb)
- Timed / Scheduled jobs

## Usage

All that is required is that you specifically set the sidekiq option for *unique* to a valid value like below:

```ruby
sidekiq_options unique: :while_executing
```

For jobs scheduled in the future it is possible to set for how long the job
should be unique. The job will be unique for the number of seconds configured (default 30 minutes)
or until the job has been completed. Thus, the job will be unique for the shorter of the two.  Note that Sidekiq versions before 3.0 will remove job keys after an hour, which means jobs can remain unique for at most an hour.

If you want the unique job to stick around even after it has been successfully
processed then just set `unique: :until_timeout`.

You can also control the `lock_expiration` of the uniqueness check. If you want to enforce uniqueness over a longer period than the default of 30 minutes then you can pass the number of seconds you want to use to the sidekiq options:

```ruby
sidekiq_options unique: :until_timeout, lock_expiration: 120 * 60 # 2 hours
```

For locking modes (`:while_executing` and `:until_and_while_executing`) you can control the expiration length of the runtime uniqueness. If you want to enforce uniqueness over a longer period than the default of 60 seconds, then you can pass the number of seconds you want to use to the sidekiq options:

```ruby
sidekiq_options unique: :while_executing, lock_expiration: 2 * 60 # 2 minutes
```

Requiring the gem in your gemfile should be sufficient to enable unique jobs.

### Usage with ActiveJob

```ruby
Sidekiq.default_worker_options = {
  unique: :until_executing,
  unique_args: ->(args) { [ args.first.except('job_id') ] }
}
```


### Finer Control over Uniqueness

Sometimes it is desired to have a finer control over which arguments are used in determining uniqueness of the job, and others may be _transient_. For this use-case, you need to define either a `unique_args` method, or a ruby proc.

The unique_args method need to return an array of values to use for uniqueness check.

The method or the proc can return a modified version of args without the transient arguments included, as shown below:

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing,
                  unique_args: :unique_args

  def self.unique_args(args)
    [ args[0], args[2][:type] ]
  end

  ...

end

class UniqueJobWithFilterProc
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  unique_args: ->(args) { [ args.first ] }

  ...

end
```

The previous problems with unique args being string in server and symbol in client is no longer a problem because the `UniqueArgs` class accounts for this and converts everything to json now. If you find an edge case please provide and example so that we can add coverage and fix it.


It is also quite possible to ensure different types of unique args based on context. I can't vouch for the below example but see [#203](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/203) for the discussion.

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing, unique_args: :unique_args

  def self.unique_args(args)
    if Sidekiq::ProcessSet.new.size > 1
      # sidekiq runtime; uniqueness for the object (first arg)
      args.first
    else
      # queuing from the app; uniqueness for all params
      args
    end
  end
end
```


### After Unlock Callback

If you are using :after_yield as your unlock ordering, Unique Job offers a callback to perform some work after the block is yielded.

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing,

  def after_unlock
   # block has yielded and lock is released
  end
  ...
end.

```

### Logging

To see logging in sidekiq when duplicate payload has been filtered out you can enable on a per worker basis using the sidekiq options.  The default value is false

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing,
                  log_duplicate_payload: true

  ...

end
```

## Debugging
There are two ways to display and remove keys regarding uniqueness. The console way and the command line way.

### Console
Start the console with the following command `bundle exec jobs console`.

#### List Unique Keys
`keys '*', 100`

#### Remove Unique Keys
`del '*', 100, false` the dry_run and count parameters are both required. This is to have some type of protection against clearing out all uniqueness.

### Command Line

`bundle exec jobs` displays help on how to use the unique jobs command line.

## Communication

There is a [![Join the chat at https://gitter.im/mhenrixon/sidekiq-unique-jobs](https://badges.gitter.im/mhenrixon/sidekiq-unique-jobs.svg)](https://gitter.im/mhenrixon/sidekiq-unique-jobs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) for praise or scorn. This would be a good place to have lengthy discuss or brilliant suggestions or simply just nudge me if I forget about anything.

## Testing

To enable the testing for `sidekiq-unique-jobs`, add `require 'sidekiq_unique_jobs/testing'` to your testing helper.

You can if you want use `gem 'mock_redis'` to prevent sidekiq unique jobs using redis.

See https://github.com/mhenrixon/sidekiq-unique-jobs/tree/master/rails_example/spec/controllers/work_controller_spec.rb for an example of how to configure sidekiq and unique jobs without redis.

If you really don't care about testing uniquness and trust we get that stuff right you can (in newer sidekiq versions) remove the client middleware.

```ruby
describe "Some test" do
  before(:each) do
    Sidekiq.configure_client do |config|
      config.client_middleware do |chain|
        chain.remove SidekiqUniqueJobs::Client::Middleware
      end
    end
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

In no particular order:

- https://github.com/salrepe
- https://github.com/rickenharp
- https://github.com/sax
- https://github.com/eduardosasso
- https://github.com/KensoDev
- https://github.com/adstage-david
- https://github.com/jprincipe
- https://github.com/crberube
- https://github.com/simonoff
