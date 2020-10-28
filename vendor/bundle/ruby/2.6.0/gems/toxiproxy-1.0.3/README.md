# toxiproxy-ruby

`toxiproxy-ruby` `1.x` (latest) is compatible with the Toxiproxy `2.x` series.
`toxiproxy-ruby` `0.x` is compatible with the Toxiproxy `1.x` series.

[Toxiproxy](https://github.com/shopify/toxiproxy) is a proxy to simulate network
and system conditions. The Ruby API aims to make it simple to write tests that
ensure your application behaves appropriately under harsh conditions. Before you
can use the Ruby library, you need to read the [Usage section of the Toxiproxy
README](https://github.com/shopify/toxiproxy#usage).

```
gem install toxiproxy
```

Make sure the Toxiproxy server is already running.

For more information about Toxiproxy and the available toxics, see the [Toxiproxy
documentation](https://github.com/shopify/toxiproxy)

## Usage

The Ruby client communicates with the Toxiproxy daemon via HTTP. By default it
connects to `http://127.0.0.1:8474`, but you can point to any host:

```ruby
Toxiproxy.host = 'http://toxiproxy.local:5665'
```

For example, to simulate 1000ms latency on a database server you can use the
`latency` toxic with the `latency` argument (see the Toxiproxy project for a
list of all toxics):

```ruby
Toxiproxy[:mysql_master].toxic(:latency, latency: 1000).apply do
  Shop.first # this took at least 1s
end
```

You can also take an endpoint down for the duration of a block at the TCP level:

```ruby
Toxiproxy[:mysql_master].down do
  Shop.first # this'll raise
end
```

If you want to simulate all your Redis instances being down:

```ruby
Toxiproxy[/redis/].down do
  # any redis call will fail
end
```

If you want to simulate that your cache server is slow at incoming network
(upstream), but fast at outgoing (downstream), you can apply a toxic to just the
upstream:

```ruby
Toxiproxy[:cache].upstream(:latency, latency: 1000).apply do
  Cache.get(:omg) # will take at least a second
end
```

By default the toxic is applied to the downstream connection, you can be
explicit and chain them:

```ruby
Toxiproxy[/redis/].upstream(:slow_close, delay: 100).downstream(:latency, jitter: 300).apply do
  # all redises are now slow at responding and closing
end
```

See the [Toxiproxy README](https://github.com/shopify/toxiproxy#Toxics) for a
list of toxics.

## Populate

To populate Toxiproxy pass the proxy configurations to `Toxiproxy#populate`:

```ruby
Toxiproxy.populate([{
  name: "mysql_master",
  listen: "localhost:21212",
  upstream: "localhost:3306",
},{
  name: "mysql_read_only",
  listen: "localhost:21213",
  upstream: "localhost:3306",
}])
```

This will create the proxies passed, or replace the proxies if they already exist in Toxiproxy.
It's recommended to do this early as early in boot as possible, see the
[Toxiproxy README](https://github.com/shopify/toxiproxy#usage). If you have many
proxies, we recommend storing the Toxiproxy configs in a configuration file and
deserializing it into `Toxiproxy.populate`.

If you're doing this in Rails, you may have to do this in `config/boot.rb` (as
early in boot as possible) as older versions of `ActiveRecord` establish a
database connection as soon as it's loaded.
