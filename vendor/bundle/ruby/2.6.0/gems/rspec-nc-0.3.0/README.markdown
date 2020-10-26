RSpec Notification Center
=========================

[![Build Status](https://travis-ci.org/twe4ked/rspec-nc.svg?branch=master)](https://travis-ci.org/twe4ked/rspec-nc)
[![Dependency status](https://gemnasium.com/twe4ked/rspec-nc.png)](https://gemnasium.com/twe4ked/rspec-nc)

rspec-nc is an RSpec formatter for Mountain Lion's Notification Center.

![Screenshot](http://twe4ked.github.io/rspec-nc/rspec-nc.jpg)

Installation
------------

Installing rspec-nc is easy.
Just put it in your Gemfile (`gem 'rspec-nc'`) and run your specs:

```
rspec --format=doc --format=Nc
```

You will want to specify another formatter as rspec-nc does not provide any
other output.

If you want to use rspec-nc as your default formatter, simply put this option
in your .rspec file:

```
--format Nc
```

Contributing
------------

Found an issue? Have a great idea? Want to help? Great! Create an issue issue
for it, or even better; fork the project and fix the problem yourself. Pull
requests are always welcome. :)

### Running the specs

The default rake task uses [WWTD] to test multiple versions of RSpec.

``` ruby
rake

# with a formatter
FORMATTER=Nc rake
```

[WWTD]: https://github.com/grosser/wwtd
