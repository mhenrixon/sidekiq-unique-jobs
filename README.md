# SidekiqUniqueJobs [![Join the chat at https://gitter.im/mhenrixon/sidekiq-unique-jobs][image-1]][1] [![Build Status][image-2]][2] [![Code Climate][image-3]][3] [![Test Coverage][image-4]][4]

<!-- MarkdownTOC -->

- [Introduction](#introduction)
- [Documentation](#documentation)
- [Requirements](#requirements)
- [Installation](#installation)
- [Support Me](#support-me)
- [Usage](#usage)
  - [While Executing](#while-executing)
    - [](#)
    - [Example](#example)
- [Debugging](#debugging)
  - [Sidekiq Web](#sidekiq-web)
    - [Show Unique Digests](#show-unique-digests)
    - [Show keys for digest](#show-keys-for-digest)
- [Communication](#communication)
- [Testing](#testing)
- [ActiveJob](#activejob)
- [redis-namespace](#redis-namespace)
- [Contributing](#contributing)
- [Contributors](#contributors)

<!-- /MarkdownTOC -->

## Introduction

The goal of this gem is to ensure your Sidekiq jobs are unique. We do this by creating unique keys in Redis based on how you configure uniqueness.

## Documentation

This is the documentation for the master branch. You can find the documentation for each release by navigating to its tag: [v5.0.10][21]

Below are links to the latest major versions (4 & 5):

- [v5.0.10][22]
- [v4.0.18][23]

## Requirements

- Sidekiq `>= 4.0` (`>= 5.2` recommended)
- Ruby:
  - MRI `>= 2.3` (`>= 2.5` recommended)
  - JRuby `>= 9.0` (`>= 9.2` recommended)
  - Truffleruby WIP (Working on getting it supported)
  - Rubinius officially not supported (Haven't really tried)
- Redis Server `>= 3.0.2` (`>= 3.2` recommended)
- [ActiveJob officially not supported][48]
- [redis-namespace officially not supported][49]

See [Sidekiq requirements][24] for detailed requirements of Sidekiq itself.

## Installation

Add this line to your application's Gemfile:

```
gem 'sidekiq-unique-jobs'
```

And then execute:

```
bundle
```

Or install it yourself as:

```
gem install sidekiq-unique-jobs
```

## Support Me

Want to show me some ❤️ for the hard work I do on this gem? You can use the following PayPal link [https://paypal.me/mhenrixon][25]. Any amount is welcome and let me tell you it feels good to be appreciated. Even a dollar makes me super excited about all of this.

## Usage

### While Executing

Jobs with this lock can be scheduled any number of times. Nothing prevents these jobs from being enqueued by Sidekiq. The uniqueness of the job is enforced only while the Sidekiq server is processing jobs.

####

#### Example

```ruby
class WhileExecutingWorker
  include Sidekiq::Worker
  sidekiq_options lock: :while_executing

  def perform(id)
    puts "Hello"
    sleep 1
    puts "Bye"
  end
end
```

```ruby
3.times { WhileExecutingWorker.perform_async(1) }
```

We immediately get the following logs in sidekiq:

```
7:39:02 PM worker.1 |  2019-04-27T17:39:02.447Z pid=90150 tid=ox4ybzaai class=WhileExecutingWorker jid=1d69086361d02099be04a86c INFO: start
7:39:02 PM worker.1 |  2019-04-27T17:39:02.447Z pid=90150 tid=ox4ybzajq class=WhileExecutingWorker jid=239b4bebf35fc84148229b01 INFO: start
7:39:02 PM worker.1 |  2019-04-27T17:39:02.450Z pid=90150 tid=ox4ybz89u class=WhileExecutingWorker jid=156e07ba613c7e2a6d5fcb91 INFO: start
```

## Debugging

There are several ways of removing keys that are stuck. The prefered way is by using the unique extension to `Sidekiq::Web`. The old console and command line versions still work but might be deprecated in the future. It is better to search for the digest itself and delete the keys matching that digest.

### Sidekiq Web

To use the web extension you need to require it in your routes.

```ruby
# app/config/routes.rb
require 'sidekiq_unique_jobs/web'
mount Sidekiq::Web, at: '/sidekiq'
```

There is no need to `require 'sidekiq/web'` since `sidekiq_unique_jobs/web`
already does this.

To filter/search for keys we can use the wildcard `*`. If we have a unique digest `'uniquejobs:9e9b5ce5d423d3ea470977004b50ff84` we can search for it by enter `*ff84` and it should return all digests that end with `ff84`.

#### Show Unique Digests

![Unique Digests][image-5]

#### Show keys for digest

![Unique Digests][image-6]

## Communication

There is a [![Join the chat at https://gitter.im/mhenrixon/sidekiq-unique-jobs][image-7]][26] for praise or scorn. This would be a good place to have lengthy discuss or brilliant suggestions or simply just nudge me if I forget about anything.

## Testing

This has been probably the most confusing part of this gem. People get really confused with how unreliable the unique jobs have been. I there for decided to do what Mike is doing for sidekiq enterprise. Read the section about unique jobs.

[Enterprise unique jobs][27]

```ruby
SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end
```

If you truly wanted to test the sidekiq client push you could do something like below. Note that it will only work for the jobs that lock when the client pushes the job to redis (UntilExecuted, UntilAndWhileExecuting and UntilExpired).

```ruby
RSpec.describe Workers::CoolOne do
  before do
    SidekiqUniqueJobs.config.enabled = false
  end

  # ... your tests that don't test uniqueness

  context 'when Sidekiq::Testing.disabled?' do
    before do
      Sidekiq::Testing.disable!
      Sidekiq.redis(&:flushdb)
    end

    after do
      Sidekiq.redis(&:flushdb)
    end

    it 'prevents duplicate jobs from being scheduled' do
      SidekiqUniqueJobs.use_config(enabled: true) do
        expect(described_class.perform_in(3600, 1)).not_to eq(nil)
        expect(described_class.perform_async(1)).to eq(nil)
      end
    end
  end
end
```

I would strongly suggest you let this gem test uniqueness. If you care about how the gem is integration tested have a look at the following specs:

- [spec/integration/sidekiq\_unique\_jobs/lock/until\_and\_while\_executing\_spec.rb][28]
- [spec/integration/sidekiq\_unique\_jobs/lock/until\_executed\_spec.rb][29]
- [spec/integration/sidekiq\_unique\_jobs/lock/until\_expired\_spec.rb][30]
- [spec/integration/sidekiq\_unique\_jobs/lock/while\_executing\_reject\_spec.rb][31]
- [spec/integration/sidekiq\_unique\_jobs/lock/while\_executing\_spec.rb][32]

## ActiveJob

Version 6 requires Redis \>= 3 and pure Sidekiq, no ActiveJob supported anymore. See [About ActiveJob][33] for why.

## redis-namespace

Will not be officially supported anymore. Since Mike [won't support redis-namespace][34] neither will I.

[Read this][35] for how to migrate away from namespacing.


## Contributing

1. Fork it
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create new Pull Request

## Contributors

You can find a list of contributors over on [Contributors][36]

[1]:	https://gitter.im/mhenrixon/sidekiq-unique-jobs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[2]:	https://travis-ci.org/mhenrixon/sidekiq-unique-jobs
[3]:	https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs
[4]:	https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/coverage
[5]:	#introduction
[6]:	#documentation
[7]:	#requirements
[8]:	#installation
[9]:	#support-me
[10]:	#usage
[11]:	#debugging
[12]:	#sidekiq-web
[13]:	#show-unique-digests
[14]:	#show-keys-for-digest
[15]:	#communication
[16]:	#testing
[17]:	#activejob
[18]:	#redis-namespace
[19]:	#contributing
[20]:	#contributors
[21]:	https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10.
[22]:	https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10.
[23]:	https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.18
[24]:	https://github.com/mperham/sidekiq#requirements
[25]:	https://paypal.me/mhenrixon
[26]:	https://gitter.im/mhenrixon/sidekiq-unique-jobs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[27]:	https://www.dailydrip.com/topics/sidekiq/drips/sidekiq-enterprise-unique-jobs
[28]:	https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/integration/sidekiq_unique_jobs/lock/until_and_while_executing_spec.rb
[29]:	https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/integration/sidekiq_unique_jobs/lock/until_executed_spec.rb
[30]:	https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/integration/sidekiq_unique_jobs/lock/until_expired_spec.rb
[31]:	https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/integration/sidekiq_unique_jobs/lock/while_executing_reject_spec.rb
[32]:	https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/integration/sidekiq_unique_jobs/lock/while_executing_spec.rb
[33]:	https://github.com/mhenrixon/sidekiq-unique-jobs/wiki/About-ActiveJob
[34]:	https://github.com/mperham/sidekiq/issues/3366#issuecomment-284270120
[35]:	http://www.mikeperham.com/2017/04/10/migrating-from-redis-namespace/
[36]:	https://github.com/mhenrixon/sidekiq-unique-jobs/graphs/contributors

[image-1]:	https://badges.gitter.im/mhenrixon/sidekiq-unique-jobs.svg
[image-2]:	https://travis-ci.org/mhenrixon/sidekiq-unique-jobs.png?branch=master
[image-3]:	https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs.png
[image-4]:	https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/badges/coverage.svg
[image-5]:	assets/unique_digests_1.png
[image-6]:	assets/unique_digests_2.png
[image-7]:	https://badges.gitter.im/mhenrixon/sidekiq-unique-jobs.svg
