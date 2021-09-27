# frozen_string_literal: true

module SidekiqUniqueJobs
  module Testing
    #
    # Module Redis provides more convenient access to redis
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    # rubocop:disable Naming/MethodParameterName, Metrics/ModuleLength
    # :nodoc:
    # :nocov:
    module Redis
      def queue(*command)
        redis { |conn| conn.queue(*command) }
      end

      def commit
        redis(&:commit)
      end

      def select(db)
        redis { |conn| conn.select(db) }
      end

      def ping(message = nil)
        redis { |conn| conn.ping(message) }
      end

      def echo(value)
        redis { |conn| conn.echo(value) }
      end

      def quit
        redis(&:quit)
      end

      def bgrewriteaof
        redis(&:bgrewriteaof)
      end

      def bgsave
        redis(&:bgsave)
      end

      def config(action, *args)
        redis { |conn| conn.config(action, *args) }
      end

      def client(_subcommand = nil, *args)
        redis { |conn| conn.client(subcommand, *args) }
      end

      def dbsize
        redis(&:dbsize)
      end

      def debug(*args)
        redis { |conn| conn.debug(*args) }
      end

      def flushall(options = nil)
        redis { |conn| conn.flushall(options) }
      end

      def flushdb(options = nil)
        redis { |conn| conn.flushdb(options) }
      end

      def info(cmd = nil)
        redis { |conn| conn.info(cmd) }
      end

      def lastsave
        redis(&:lastsave)
      end

      def monitor(&block)
        redis { |conn| conn.monitor(&block) }
      end

      def save
        redis(&:save)
      end

      def shutdown
        redis(&:shutdown)
      end

      def slaveof(host, port)
        redis { |conn| conn.slaveof(host, port) }
      end

      def slowlog(subcommand, length = nil)
        redis { |conn| conn.slowlog(subcommand, length) }
      end

      def sync
        redis(&:sync)
      end

      def time
        redis(&:time)
      end

      def persist(key)
        redis { |conn| conn.persist(key) }
      end

      def expire(key, seconds)
        redis { |conn| conn.expire(key, seconds) }
      end

      def expireat(key, unix_time)
        redis { |conn| conn.expireat(key, unix_time) }
      end

      def ttl(key)
        redis { |conn| conn.ttl(key) }
      end

      def pexpire(key, milliseconds)
        redis { |conn| conn.pexpire(key, milliseconds) }
      end

      def pexpireat(key, ms_unix_time)
        redis { |conn| conn.pexpireat(key, ms_unix_time) }
      end

      def pttl(key)
        redis { |conn| conn.pttl(key) }
      end

      def dump(key)
        redis { |conn| conn.dump(key) }
      end

      def restore(key, ttl, serialized_value, options = {})
        redis { |conn| conn.restore(key, ttl, serialized_value, options) }
      end

      def migrate(key, options)
        redis { |conn| conn.migrate(key, options) }
      end

      def del(*keys)
        redis { |conn| conn.del(*keys) }
      end

      def unlink(*keys)
        redis { |conn| conn.unlink(*keys) }
      end

      def exists(key)
        redis do |conn|
          # TODO: Remove the if statement in the future
          value =
            if conn.respond_to?(:exists?)
              conn.exists?(key)
            else
              conn.exists(key)
            end
          return true  if value.is_a?(TrueClass)
          return false if value.is_a?(FalseClass)

          value.positive?
        end
      end

      def keys(pattern = "*")
        redis { |conn| conn.keys(pattern) }
      end

      def move(key, db)
        redis { |conn| conn.move(key, db) }
      end

      def randomkey
        redis(&:randomkey)
      end

      def rename(old_name, new_name)
        redis { |conn| conn.rename(old_name, new_name) }
      end

      def renamenx(old_name, new_name)
        redis { |conn| conn.renamenx(old_name, new_name) }
      end

      def sort(key, options = {})
        redis { |conn| conn.sort(key, options) }
      end

      def type(key)
        redis { |conn| conn.type(key) }
      end

      def decr(key)
        redis { |conn| conn.decr(key) }
      end

      def decrby(key, decrement)
        redis { |conn| conn.decrby(key, decrement) }
      end

      def incr(key)
        redis { |conn| conn.incr(key) }
      end

      def incrby(key, increment)
        redis { |conn| conn.incrby(key, increment) }
      end

      def incrbyfloat(key, increment)
        redis { |conn| conn.incrbyfloat(key, increment) }
      end

      def set(key, value, options = {})
        redis { |conn| conn.set(key, value, **options) }
      end

      def setex(key, ttl, value)
        redis { |conn| conn.setex(key, ttl, value) }
      end

      def psetex(key, ttl, value)
        redis { |conn| conn.psetex(key, ttl, value) }
      end

      def setnx(key, value)
        redis { |conn| conn.setnx(key, value) }
      end

      def mset(*args)
        redis { |conn| conn.mset(*args) }
      end

      def mapped_mset(hash)
        redis { |conn| conn.mapped_mset(hash) }
      end

      def msetnx(*args)
        redis { |conn| conn.msetnx(*args) }
      end

      def mapped_msetnx(hash)
        redis { |conn| conn.mapped_msetnx(hash) }
      end

      def mget(*keys, &blk)
        redis { |conn| conn.mget(*keys, &blk) }
      end

      def mapped_mget(*keys)
        redis { |conn| conn.mapped_mget(*keys) }
      end

      def get(key)
        redis { |conn| conn.get(key) }
      end

      def setrange(key, offset, value)
        redis { |conn| conn.setrange(key, offset, value) }
      end

      def getrange(key, start, stop)
        redis { |conn| conn.getrange(key, start, stop) }
      end

      def setbit(key, offset, value)
        redis { |conn| conn.setbit(key, offset, value) }
      end

      def getbit(key, offset)
        redis { |conn| conn.getbit(key, offset) }
      end

      def append(key, value)
        redis { |conn| conn.append(key, value) }
      end

      def bitcount(key, start = 0, stop = -1)
        redis { |conn| conn.bitcount(key, start, stop) }
      end

      def bitop(operation, destkey, *keys)
        redis { |conn| conn.bitop(operation, destkey, *keys) }
      end

      def bitpos(key, bit, start = nil, stop = nil)
        redis { |conn| conn.bitpos(key, bit, start, stop) }
      end

      def getset(key, value)
        redis { |conn| conn.getset(key, value) }
      end

      def strlen(key)
        redis { |conn| conn.strlen(key) }
      end

      def llen(key)
        redis { |conn| conn.llen(key) }
      end

      def lpush(key, value)
        redis { |conn| conn.lpush(key, value) }
      end

      def lpushx(key, value)
        redis { |conn| conn.lpushx(key, value) }
      end

      def rpush(key, value)
        redis { |conn| conn.rpush(key, value) }
      end

      def rpushx(key, value)
        redis { |conn| conn.rpushx(key, value) }
      end

      def lpop(key)
        redis { |conn| conn.lpop(key) }
      end

      def rpop(key)
        redis { |conn| conn.rpop(key) }
      end

      def rpoplpush(source, destination)
        redis { |conn| conn.rpoplpush(source, destination) }
      end

      def blpop(*args)
        redis { |conn| conn.blpop(*args) }
      end

      def brpop(*args)
        redis { |conn| conn.brpop(*args) }
      end

      def brpoplpush(source, destination, options = {})
        redis { |conn| conn.brpoplpush(source, destination, **options) }
      end

      def lindex(key, index)
        redis { |conn| conn.lindex(key, index) }
      end

      def linsert(key, where, pivot, value)
        redis { |conn| conn.linsert(key, where, pivot, value) }
      end

      def lrange(key, start, stop)
        redis { |conn| conn.lrange(key, start, stop) }
      end

      def lrem(key, count, value)
        redis { |conn| conn.lrem(key, count, value) }
      end

      def lset(key, index, value)
        redis { |conn| conn.lset(key, index, value) }
      end

      def ltrim(key, start, stop)
        redis { |conn| conn.ltrim(key, start, stop) }
      end

      def scard(key)
        redis { |conn| conn.scard(key) }
      end

      def sadd(key, member)
        redis { |conn| conn.sadd(key, member) }
      end

      def srem(key, member)
        redis { |conn| conn.srem(key, member) }
      end

      def spop(key, count = nil)
        redis { |conn| conn.spop(key, count) }
      end

      def srandmember(key, count = nil)
        redis { |conn| conn.srandmember(key, count) }
      end

      def smove(source, destination, member)
        redis { |conn| conn.smove(source, destination, member) }
      end

      def sismember(key, member)
        redis { |conn| conn.sismember(key, member) }
      end

      def smembers(key)
        redis { |conn| conn.smembers(key) }
      end

      def sdiff(*keys)
        redis { |conn| conn.sdiff(*keys) }
      end

      def sdiffstore(destination, *keys)
        redis { |conn| conn.sdiffstore(destination, *keys) }
      end

      def sinter(*keys)
        redis { |conn| conn.sinter(*keys) }
      end

      def sinterstore(destination, *keys)
        redis { |conn| conn.sinterstore(destination, *keys) }
      end

      def sunion(*keys)
        redis { |conn| conn.sunion(*keys) }
      end

      def sunionstore(destination, *keys)
        redis { |conn| conn.sunionstore(destination, *keys) }
      end

      def zcard(key)
        redis { |conn| conn.zcard(key) }
      end

      def zadd(key, *args)
        redis { |conn| conn.zadd(key, *args) }
      end

      def zincrby(key, increment, member)
        redis { |conn| conn.zincrby(key, increment, member) }
      end

      def zrem(key, member)
        redis { |conn| conn.zrem(key, member) }
      end

      def zpopmax(key, count = nil)
        redis { |conn| conn.zpopmax(key, count) }
      end

      def zpopmin(key, count = nil)
        redis { |conn| conn.zpopmin(key, count) }
      end

      def bzpopmax(*args)
        redis { |conn| conn.bzpopmax(*args) }
      end

      def bzpopmin(*args)
        redis { |conn| conn.bzpopmin(*args) }
      end

      def zscore(key, member)
        redis { |conn| conn.zscore(key, member) }
      end

      def zrange(key, start, stop, options = {})
        redis { |conn| conn.zrange(key, start, stop, options) }
      end

      def zrevrange(key, start, stop, options = {})
        redis { |conn| conn.zrevrange(key, start, stop, options) }
      end

      def zrank(key, member)
        redis { |conn| conn.zrank(key, member) }
      end

      def zrevrank(key, member)
        redis { |conn| conn.zrevrank(key, member) }
      end

      def zremrangebyrank(key, start, stop)
        redis { |conn| conn.zremrangebyrank(key, start, stop) }
      end

      def zlexcount(key, min, max)
        redis { |conn| conn.zlexcount(key, min, max) }
      end

      def zrangebylex(key, min, max, options = {})
        redis { |conn| conn.zrangebylex(key, min, max, options) }
      end

      def zrevrangebylex(key, max, min, options = {})
        redis { |conn| conn.zrevrangebylex(key, max, min, options) }
      end

      def zrangebyscore(key, min, max, options = {})
        redis { |conn| conn.zrangebyscore(key, min, max, options) }
      end

      def zrevrangebyscore(key, max, min, options = {})
        redis { |conn| conn.zrevrangebyscore(key, max, min, options) }
      end

      def zremrangebyscore(key, min, max)
        redis { |conn| conn.zremrangebyscore(key, min, max) }
      end

      def zcount(key, min, max)
        redis { |conn| conn.zcount(key, min, max) }
      end

      def zinterstore(destination, keys, options = {})
        redis { |conn| conn.zinterstore(destination, keys, options) }
      end

      def zunionstore(destination, keys, options = {})
        redis { |conn| conn.zunionstore(destination, keys, options) }
      end

      def hlen(key)
        redis { |conn| conn.hlen(key) }
      end

      def hset(key, field, value)
        redis { |conn| conn.hset(key, field, value) }
      end

      def hsetnx(key, field, value)
        redis { |conn| conn.hsetnx(key, field, value) }
      end

      def hmset(key, *attrs)
        redis { |conn| conn.hmset(key, *attrs) }
      end

      def mapped_hmset(key, hash)
        redis { |conn| conn.mapped_hmset(key, hash) }
      end

      def hget(key, field)
        redis { |conn| conn.hget(key, field) }
      end

      def hmget(key, *fields, &blk)
        redis { |conn| conn.hmget(key, *fields, &blk) }
      end

      def mapped_hmget(key, *fields)
        redis { |conn| conn.mapped_hmget(key, *fields) }
      end

      def hdel(key, *fields)
        redis { |conn| conn.hdel(key, *fields) }
      end

      def hexists(key, field)
        redis { |conn| conn.hexists(key, field) }
      end

      def hincrby(key, field, increment)
        redis { |conn| conn.hincrby(key, field, increment) }
      end

      def hincrbyfloat(key, field, increment)
        redis { |conn| conn.hincrbyfloat(key, field, increment) }
      end

      def hkeys(key)
        redis { |conn| conn.hkeys(key) }
      end

      def hvals(key)
        redis { |conn| conn.hvals(key) }
      end

      def hgetall(key)
        redis { |conn| conn.hgetall(key) }
      end

      def publish(channel, message)
        redis { |conn| conn.publish(channel, message) }
      end

      def subscribed?
        redis(&:subscribed?)
      end

      def subscribe(*channels, &block)
        redis { |conn| conn.subscribe(*channels, &block) }
      end

      def subscribe_with_timeout(timeout, *channels, &block)
        redis { |conn| conn.subscribe_with_timeout(timeout, *channels, &block) }
      end

      def unsubscribe(*channels)
        redis { |conn| conn.unsubscribe(*channels) }
      end

      def psubscribe(*channels, &block)
        redis { |conn| conn.psubscribe(*channels, &block) }
      end

      def psubscribe_with_timeout(timeout, *channels, &block)
        redis { |conn| conn.psubscribe_with_timeout(timeout, *channels, &block) }
      end

      def punsubscribe(*channels)
        redis { |conn| conn.punsubscribe(*channels) }
      end

      def pubsub(subcommand, *args)
        redis { |conn| conn.pubsub(subcommand, *args) }
      end

      def watch(*keys)
        redis { |conn| conn.watch(*keys) }
      end

      def unwatch
        redis(&:unwatch)
      end

      def pipelined
        redis(&:pipelined)
      end

      def multi
        redis(&:multi)
      end

      def exec
        redis(&:exec)
      end

      def discard
        redis(&:discard)
      end

      def scan(cursor, options = {})
        redis { |conn| conn.scan(cursor, options) }
      end

      def scan_each(options = {}, &block)
        redis { |conn| conn.scan_each(options, &block) }
      end

      def hscan(key, cursor, options = {})
        redis { |conn| conn.hscan(key, cursor, options) }
      end

      def hscan_each(key, options = {}, &block)
        redis { |conn| conn.hscan_each(key, options, &block) }
      end

      def zscan(key, cursor, options = {})
        redis { |conn| conn.zscan(key, cursor, options) }
      end

      def zscan_each(key, options = {}, &block)
        redis { |conn| conn.zscan_each(key, options, &block) }
      end

      def sscan(key, cursor, options = {})
        redis { |conn| conn.sscan(key, cursor, options) }
      end

      def sscan_each(key, options = {}, &block)
        redis { |conn| conn.sscan_each(key, options, &block) }
      end

      def pfadd(key, member)
        redis { |conn| conn.pfadd(key, member) }
      end

      def pfcount(*keys)
        redis { |conn| conn.pfcount(*keys) }
      end

      def pfmerge(dest_key, *source_key)
        redis { |conn| conn.pfmerge(dest_key, *source_key) }
      end

      def geoadd(key, *member)
        redis { |conn| conn.geoadd(key, *member) }
      end

      def geohash(key, member)
        redis { |conn| conn.geohash(key, member) }
      end

      def georadius(*args, **geoptions)
        redis { |conn| conn.georadius(*args, geoptions) }
      end

      def georadiusbymember(*args, **geoptions)
        redis { |conn| conn.georadiusbymember(*args, geoptions) }
      end

      def geopos(key, member)
        redis { |conn| conn.geopos(key, member) }
      end

      def geodist(key, member1, member2, unit = "m")
        redis { |conn| conn.geodist(key, member1, member2, unit) }
      end

      def xinfo(subcommand, key, group = nil)
        redis { |conn| conn.xinfo(subcommand, key, group) }
      end

      def xadd(key, entry, opts = {})
        redis { |conn| conn.xadd(key, entry, opts) }
      end

      def xtrim(key, maxlen, approximate: false)
        redis { |conn| conn.xtrim(key, maxlen, approximate: approximate) }
      end

      def xdel(key, *ids)
        redis { |conn| conn.xdel(key, *ids) }
      end

      def xrange(key, start = "-", stop = "+", count: nil)
        redis { |conn| conn.xrange(key, start, stop, count: count) }
      end

      def xrevrange(key, stop = "+", start = "-", count: nil)
        redis { |conn| conn.xrevrange(key, stop, start, count: count) }
      end

      def xlen(key)
        redis { |conn| conn.xlen(key) }
      end

      def xread(keys, ids, count: nil, block: nil)
        redis { |conn| conn.xread(keys, ids, count: count, block: block) }
      end

      def xgroup(subcommand, key, group, id_or_consumer = nil, mkstream: false)
        redis { |conn| conn.xgroup(subcommand, key, group, id_or_consumer, mkstream: mkstream) }
      end

      def xreadgroup(group, consumer, keys, ids, opts = {})
        redis { |conn| conn.xreadgroup(group, consumer, keys, ids, opts) }
      end

      def xack(key, group, *ids)
        redis { |conn| conn.xack(key, group, *ids) }
      end

      def xclaim(key, group, consumer, min_idle_time, *ids, **opts) # rubocop:disable Metrics/ParameterLists
        redis { |conn| conn.xclaim(key, group, consumer, min_idle_time, *ids, **opts) }
      end

      def xpending(key, group, *args)
        redis { |conn| conn.xpending(key, group, *args) }
      end

      def sentinel(subcommand, *args)
        redis { |conn| conn.sentinel(subcommand, *args) }
      end

      def cluster(subcommand, *args)
        redis { |conn| conn.cluster(subcommand, *args) }
      end

      def asking
        redis(&:asking)
      end

      def id
        redis(&:id)
      end

      def inspect
        redis(&:inspect)
      end

      def dup
        redis(&:dup)
      end

      def connection
        redis(&:connection)
      end
    end
    # rubocop:enable Naming/MethodParameterName, Metrics/ModuleLength

    module Sidekiq
      def push_item(item = {})
        ::Sidekiq::Client.push(item)
      end

      def queue_count(queue)
        redis { |conn| conn.llen("queue:#{queue}") }
      end

      def schedule_count
        zcard("schedule")
      end

      def dead_count
        zcard("dead")
      end

      def schedule_count_at(max = Time.now.to_f + (2 * 60))
        zcount("schedule", "-inf", max)
      end

      def retry_count
        zcard("retry")
      end

      def flush_redis
        redis(&:flushdb)
      rescue StandardError # rubocop:disable Lint/SuppressedException
      end
    end

    include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::JSON
    include SidekiqUniqueJobs::Script::Caller
    include SidekiqUniqueJobs::Testing::Redis
    include SidekiqUniqueJobs::Testing::Sidekiq

    def locking_jids
      queued_jids.merge(primed_jids).merge(locked_jids)
    end

    def unique_keys
      keys("uniquejobs:*") - [SidekiqUniqueJobs::CHANGELOGS, SidekiqUniqueJobs::DIGESTS]
    end

    def changelogs
      @changelogs || SidekiqUniqueJobs::Changelog.new
    end

    def digests
      @digests || SidekiqUniqueJobs::Digests.new
    end

    def queued_jids(key = nil)
      if key
        { key => lrange(key, 0, -1) }
      else
        scan_each(match: "*:QUEUED").each_with_object({}) do |redis_key, hash|
          hash[redis_key] ||= []
          hash[redis_key].concat(lrange(key, 0, -1))
        end
      end
    end

    def primed_jids(key = nil)
      if key
        { key => lrange(key, 0, -1) }
      else
        scan_each(match: "*:PRIMED").each_with_object({}) do |redis_key, hash|
          hash[redis_key] ||= []
          hash[redis_key].concat(lrange(key, 0, -1))
        end
      end
    end

    def locked_jids(key = nil)
      if key
        { key => hgetall(key).to_h }
      else
        scan_each(match: "*:LOCKED").each_with_object({}) do |redis_key, hash|
          hash[redis_key] = hgetall(redis_key).to_h
        end
      end
    end

    def now_f
      SidekiqUniqueJobs.now_f
    end
  end
end
