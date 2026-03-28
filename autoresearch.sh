#!/usr/bin/env bash
set -euo pipefail

# Pre-checks
command -v ruby >/dev/null 2>&1 || { echo "Ruby required"; exit 1; }
redis-cli ping >/dev/null 2>&1 || { echo "Redis not running"; exit 1; }

echo "--- AUTORESEARCH BENCHMARK START ---"

# Flush test DB
redis-cli -n 0 FLUSHDB >/dev/null

# Run the Redis operation counter benchmark
ruby -e '
require "bundler/setup"
require "sidekiq"
require "sidekiq-unique-jobs"
require "json"

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

SidekiqUniqueJobs.configure do |config|
  config.debug_lua = false
  config.max_history = 0  # Disable changelog for accurate counting
  config.lock_info = false
  config.logger_enabled = false
end

SidekiqUniqueJobs.redis { |conn| conn.call("FLUSHDB") }

def create_item(lock_type: "until_executed", lock_ttl: nil, jid: nil)
  item = {
    "jid" => jid || SecureRandom.hex(12),
    "class" => "TestWorker",
    "queue" => "default",
    "lock" => lock_type,
    "args" => ["test_arg"],
    "lock_args" => ["test_arg"],
    "lock_timeout" => 0,
    "lock_ttl" => lock_ttl,
    "lock_limit" => 1,
    "on_client_conflict" => :reject,
    "on_server_conflict" => :reject,
  }
  SidekiqUniqueJobs::Job.prepare(item)
  item
end

# Monitor Redis commands using MONITOR for a short burst
# Instead, count keys before/after and use timing

results = {}
lock_types = %w[until_executed until_expired while_executing]

# Measure 1: Redis commands per full lock lifecycle (lock + unlock)
# We use redis INFO commandstats to count
lock_types.each do |lt|
  SidekiqUniqueJobs.redis { |conn| conn.call("FLUSHDB") }
  SidekiqUniqueJobs.redis { |conn| conn.call("CONFIG", "RESETSTAT") }

  ttl = lt == "until_expired" ? 60_000 : nil
  item = create_item(lock_type: lt, lock_ttl: ttl)
  locksmith = SidekiqUniqueJobs::Locksmith.new(item)

  locksmith.lock
  locksmith.unlock

  stats = SidekiqUniqueJobs.redis { |conn| conn.call("INFO", "commandstats") }
  total_calls = stats.scan(/cmdstat_(\w+):calls=(\d+)/).reject { |cmd, _|
    %w[info config flushdb replconf].include?(cmd.downcase)
  }.sum { |_, count| count.to_i }

  results["#{lt}_commands"] = total_calls
end

# Measure 2: Keys created per lock
lock_types.each do |lt|
  SidekiqUniqueJobs.redis { |conn| conn.call("FLUSHDB") }

  ttl = lt == "until_expired" ? 60_000 : nil
  item = create_item(lock_type: lt, lock_ttl: ttl)
  locksmith = SidekiqUniqueJobs::Locksmith.new(item)
  locksmith.lock

  key_count = SidekiqUniqueJobs.redis { |conn| conn.call("DBSIZE") }
  results["#{lt}_keys_while_locked"] = key_count

  locksmith.unlock
  key_count_after = SidekiqUniqueJobs.redis { |conn| conn.call("DBSIZE") }
  results["#{lt}_keys_after_unlock"] = key_count_after
end

# Measure 3: Throughput (lock+unlock cycles per second)
require "benchmark"

lock_types.each do |lt|
  SidekiqUniqueJobs.redis { |conn| conn.call("FLUSHDB") }
  iterations = 100

  elapsed = Benchmark.realtime do
    iterations.times do
      ttl = lt == "until_expired" ? 60_000 : nil
      item = create_item(lock_type: lt, lock_ttl: ttl)
      locksmith = SidekiqUniqueJobs::Locksmith.new(item)
      locksmith.lock
      locksmith.unlock
    end
  end

  results["#{lt}_ops_per_sec"] = (iterations / elapsed).round(1)
end

# Measure 4: Total commands for 100 lock+unlock cycles (the primary optimization metric)
SidekiqUniqueJobs.redis { |conn| conn.call("FLUSHDB") }
SidekiqUniqueJobs.redis { |conn| conn.call("CONFIG", "RESETSTAT") }

100.times do
  item = create_item(lock_type: "until_executed")
  locksmith = SidekiqUniqueJobs::Locksmith.new(item)
  locksmith.lock
  locksmith.unlock
end

stats = SidekiqUniqueJobs.redis { |conn| conn.call("INFO", "commandstats") }
total_commands_100 = stats.scan(/cmdstat_(\w+):calls=(\d+)/).reject { |cmd, _|
  %w[info config flushdb replconf].include?(cmd.downcase)
}.sum { |_, count| count.to_i }

results["total_redis_commands_100_cycles"] = total_commands_100

# Output all metrics
results.each do |name, value|
  puts "METRIC #{name}=#{value}"
end

# The primary metric we optimize
puts "METRIC redis_commands_per_cycle=#{(total_commands_100.to_f / 100).round(1)}"
'

echo "--- AUTORESEARCH BENCHMARK END ---"
