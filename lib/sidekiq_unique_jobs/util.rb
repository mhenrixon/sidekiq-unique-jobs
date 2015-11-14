module SidekiqUniqueJobs
  module Util
    SCAN_PATTERN ||= '*'.freeze
    DEFAULT_COUNT ||= 1_000

    module_function

    def keys(pattern = SCAN_PATTERN, count = DEFAULT_COUNT)
      scan(pattern, count: count)
    end

    def del_by(pattern = SCAN_PATTERN, count = 0, dry_run = true)
      logger.debug { "Deleting keys by: #{pattern}" }
      keys, time = timed { scan(pattern, count) }
      logger.debug { "#{keys.size} matching keys found in #{time} sec." }
      keys = dry_run(keys)
      logger.debug { "#{keys.size} matching keys after postprocessing" }
      unless dry_run
        logger.debug { "deleting #{keys}..." }
        _, time = timed { del(keys) }
        logger.debug { "Deleted in #{time} sec." }
      end
      keys.size
    end

    def del(keys)
      connection do |conn|
        keys.each_slice(500) do |chunk|
          conn.pipelined do
            chunk.each do |key|
              conn.del key
            end
          end
        end
      end
    end

    def dry_run(keys, pattern = nil)
      return keys if pattern.nil?
      regex = Regexp.new(pattern)
      keys.select { |k| regex.match k }
    end

    def timed(&block)
      start = Time.now
      result = block.call
      elapsed = (Time.now - start).round(2)
      [result, elapsed]
    end

    def scan(pattern, count = 1000)
      connection { |conn| conn.scan_each(match: prefix(pattern), count: count).to_a }
    end

    def prefix_keys(keys)
      keys = Array(keys).flatten.compact
      keys.map { |key| prefix(key) }
    end

    def prefix(key)
      return key if unique_prefix.nil?
      "#{unique_prefix}:#{key}"
    end

    def unique_prefix
      SidekiqUniqueJobs.config.unique_prefix
    end

    def connection(&block)
      SidekiqUniqueJobs.connection(&block)
    end

    def logger
      Sidekiq.logger
    end
  end
end
