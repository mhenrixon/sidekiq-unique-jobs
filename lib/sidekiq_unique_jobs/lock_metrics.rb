# frozen_string_literal: true

module SidekiqUniqueJobs
  # Thread-safe lock metrics tracker.
  # Accumulates counters in memory and flushes to Redis periodically.
  # Modeled after Sidekiq::Metrics::ExecutionTracker.
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class LockMetrics
    METRICS_PREFIX = "uniquejobs:metrics"
    METRICS_TTL = 8 * 60 * 60 # 8 hours

    EVENTS = [:locked, :lock_failed, :unlocked, :unlock_failed, :execution_failed, :reaped].freeze

    def initialize
      @counters = Hash.new(0)
      @mutex = Mutex.new
    end

    # Record a lock event
    #
    # @param event [Symbol] one of EVENTS
    # @param item [Hash] the Sidekiq job hash (needs "lock" key)
    def track(event, item)
      lock_type = item.is_a?(Hash) ? (item["lock"] || "unknown") : "unknown"
      @mutex.synchronize do
        @counters["#{lock_type}|#{event}"] += 1
        @counters["total|#{event}"] += 1
      end
    end

    # Flush in-memory counters to Redis
    #
    # @param time [Time] the current time (for bucketing)
    def flush(time = Time.now)
      data = reset
      return if data.empty?

      bucket = time.utc.strftime("%y%m%d|%-H:%M")
      key = "#{METRICS_PREFIX}|#{bucket}"

      Sidekiq.redis do |conn|
        conn.pipelined do |pipe|
          data.each { |field, count| pipe.call("HINCRBY", key, field, count) }
          pipe.call("EXPIRE", key, METRICS_TTL.to_s)
        end
      end
    end

    # Query metrics for the last N minutes
    #
    # @param minutes [Integer] how many minutes to look back
    # @return [Hash<String, Integer>] aggregated counters
    def self.query(minutes: 60)
      now = Time.now.utc
      results = Hash.new(0)

      keys = Array.new(minutes) do |i|
        t = now - (i * 60)
        "#{METRICS_PREFIX}|#{t.strftime('%y%m%d|%-H:%M')}"
      end

      Sidekiq.redis do |conn|
        responses = conn.pipelined do |pipe|
          keys.each { |key| pipe.call("HGETALL", key) }
        end

        responses.each do |data|
          next unless data.is_a?(Array) || data.is_a?(Hash)

          pairs = data.is_a?(Hash) ? data : data.each_slice(2)
          pairs.each { |field, count| results[field] += count.to_i }
        end
      end

      results
    end

    # Query and group by lock type for web UI display
    #
    # @param minutes [Integer] how many minutes to look back
    # @return [Array<Array(String, Hash)>] sorted array of [type, {event: count}]
    def self.by_type(minutes: 60)
      raw = query(minutes: minutes)
      grouped = Hash.new { |h, k| h[k] = Hash.new(0) }

      raw.each do |key, count|
        type, event = key.split("|", 2)
        grouped[type][event.to_sym] = count
      end

      grouped.sort_by { |type, _| (type == "total") ? "zzz" : type }
    end

    private

    def reset
      @mutex.synchronize do
        data = @counters.dup
        @counters.clear
        data
      end
    end
  end
end
