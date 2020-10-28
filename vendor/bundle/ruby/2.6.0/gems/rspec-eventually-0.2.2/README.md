[![Build Status](https://travis-ci.org/hawknewton/rspec-eventually.svg?branch=master)](https://travis-ci.org/hawknewton/rspec-eventually) [![Gem Version](https://badge.fury.io/rb/rspec-eventually.svg)](http://badge.fury.io/rb/rspec-eventually)
# Rspec::Eventually

I want to be able to do something like this:

```ruby
  it 'eventually matches' do
    value = 0
    Thread.new do
      sleep 1
      value = 1
    end

    expect { value }.to eventually eq 1
    expect { value }.to eventually_not eq 0

    # Ignore errors raised by the block and retry
    expect { client.get 'ABC' }.to eventually(eq 1).by_suppressing_errors

    # Change the timeout
    expect { client.get 'ZYX' }.to eventually(eq 1).within 5

    # Change the pause between retries
    expect { client.get 'ZYX' }.to eventually(eq 1).pause_for 1.5

  end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec-eventually'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec-eventually

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rspec-eventually/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
