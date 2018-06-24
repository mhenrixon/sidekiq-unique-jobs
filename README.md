# SidekiqUniqueJobs [![Join the chat at https://gitter.im/mhenrixon/sidekiq-unique-jobs](https://badges.gitter.im/mhenrixon/sidekiq-unique-jobs.svg)](https://gitter.im/mhenrixon/sidekiq-unique-jobs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://travis-ci.org/mhenrixon/sidekiq-unique-jobs.png?branch=master)](https://travis-ci.org/mhenrixon/sidekiq-unique-jobs) [![Code Climate](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs.png)](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs) [![Test Coverage](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/badges/coverage.svg)](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/coverage)

The missing unique jobs for sidekiq

# Documentation

This is the documentation for the master branch. You can find the documentation for each release by navigating to its tag: https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10. 

Below are links to the latest major versions (4 & 5):
- [v5.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10)
- [v4.0.18](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.18)

## Requirements

See https://github.com/mperham/sidekiq#requirements for what is required. Starting from 5.0.0 only sidekiq >= 4 is supported and support for MRI <=  2.1 is dropped. ActiveJob is not supported 

Version 5 requires redis >= 3

### ActiveJob

Due to the simplicity of ActiveJob and the complexity of this game there is no officially supported way of doing ActiveJob. If you want to use uniqueness you should be using sidekiq directly. I know some projects started by using ActiveJob out of ignorance and someone has to do a whole lot of work to migrate the workers to use sidekiq directly... 

If you are in this position and you can't figure it out; I have done such migrations for really big clients before. I am a consultant with a ton of experience on such jobs. My rate is fair and I am easy to get along with.

If that is not an option I apologize. This gem won't support ActiveJob moving forward. It would require monkey patching too much.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-unique-jobs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-unique-jobs

## Locking

Sidekiq consists of a client and a server. The client is responsible for pushing jobs to the queue and the server is responsible for actually processing the jobs. When the client puts the job to the queue the middleware checks for uniqueness and creates a lock. When the server then processes the job that lock is released.

### Options

#### Lock Expiration

This is probably not the configuration option you want... 

Since the client and the server are disconnected and not running inside the same process, setting a lock expiration is probably not what you want. Any keys that are used by this gem WILL be removed at the time of the expiration. For jobs that are scheduled in the future the key will expire when that job is scheduled + whatever expiration you have set.

In previous versions there was a default expiration of 30 minutes which didn't work for a lot of long running jobs. Since version 6 there will be no expiration of any jobs from the default configuration. Please don't use `lock_expiration` unless you really know what you are doing.

```ruby
sidekiq_options lock_expiration: nil # default - don't expire keys
sidekiq_options lock_expiration: 20.days # expire this lock in 20 days
```

#### Lock Timeout

This is the timeout (how long to wait) when creating the lock. By default we don't use a timeout so we won't wait for the lock to be created. If you want it is possible to set this like below.

```ruby
sidekiq_options lock_timeout: 0 # default - don't wait at all
sidekiq_options lock_timeout: 5 # wait 5 seconds
sidekiq_options lock_timeout: nil # lock indefinitely, this process won't continue until it gets a lock. VERY DANGEROUS!!
```

#### 

### Until Executing

Locks from when the client pushes the job to the queue. Will be unlocked before the server starts processing the job.

**NOTE** this is probably not so good for jobs that shouldn't be running simultaneously (aka slow jobs).

```ruby
sidekiq_options unique: :until_executing
```

### Until Executed

Locks from when the client pushes the job to the queue. Will be unlocked when the server has successfully processed the job.


```ruby
sidekiq_options unique: :until_executed
```

### Until Timeout

Locks from when the client pushes the job to the queue. Will be unlocked when the specified timeout has been reached. 

```ruby
sidekiq_options unique: :until_expired
```

### Unique Until And While Executing

Locks when the client pushes the job to the queue. The queue will be unlocked when the server starts processing the job. The server then goes on to creating a runtime lock for the job to prevent simultaneous jobs from being executed. As soon as the server starts processing a job, the client can push the same job to the queue.

```ruby
sidekiq_options unique: :until_and_while_executing
```

### While Executing

With this lock type it is possible to put any number of these jobs on the queue, but as the server pops the job from the queue it will create a lock and then wait until other locks are done processing. It *looks* like multiple jobs are running at the same time but in fact the second job will only be waiting for the first job to finish.

#### NOTE:

Unless this job is configured with a `lock_timeout: nil` or `lock_timeout: > 0` then all jobs that are attempted to be executed will just be dropped without waiting.

```ruby
sidekiq_options unique: :while_executing, lock_timeout: nil
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


### Uniqueness Scope

- Queue specific locks
- Across all queues - [examples/unique_on_all_queues_job.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/examples/unique_on_all_queues_job.rb)
- Across all workers - [examples/unique_across_workers_job.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/examples/unique_across_workers_job.rb)
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
processed then just set `unique: :until_expired`.

You can also control the `lock_expiration` of the uniqueness check. If you want to enforce uniqueness over a longer period than the default of 30 minutes then you can pass the number of seconds you want to use to the sidekiq options:

```ruby
sidekiq_options unique: :until_expired, lock_expiration: 120 * 60 # 2 hours
```

For locking modes (`:while_executing` and `:until_and_while_executing`) you can control the expiration length of the runtime uniqueness. If you want to enforce uniqueness over a longer period than the default of 60 seconds, then you can pass the number of seconds you want to use to the sidekiq options:

```ruby
sidekiq_options unique: :while_executing, lock_expiration: 2 * 60 # 2 minutes
```

Requiring the gem in your gemfile should be sufficient to enable unique jobs.

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

This has been probably the most confusing part of this gem. People get really confused with how unreliable the unique jobs have been. I there for decided to do what Mike is doing for sidekiq enterprise. Read the section about unique jobs.

https://www.dailydrip.com/topics/sidekiq/drips/sidekiq-enterprise-unique-jobs

```ruby
SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
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
