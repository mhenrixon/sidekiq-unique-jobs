require 'pathname'
require 'digest/sha1'
require 'concurrent/map'

module SidekiqUniqueJobs
  ScriptError = Class.new(StandardError)

  module Scripts
    LUA_PATHNAME ||= Pathname.new(__FILE__).dirname.join('../../redis').freeze
    SOURCE_FILES ||= Dir[LUA_PATHNAME.join('**/*.lua')].compact.freeze
    DEFINED_METHODS ||= [].freeze
    SCRIPT_SHAS ||= Concurrent::Map.new

    module_function

    extend SingleForwardable
    def_delegator :SidekiqUniqueJobs, :connection

    def logger
      Sidekiq.logger
    end

    def call(file_name, redis_pool, options = {}) # rubocop:disable MethodLength
      connection(redis_pool) do |redis|
        if SCRIPT_SHAS[file_name].nil?
          SCRIPT_SHAS[file_name] = redis.script(:load, script_source(file_name))
        end
        redis.evalsha(SCRIPT_SHAS[file_name], options)
      end
    rescue Redis::CommandError => ex
      if ex.message == 'NOSCRIPT No matching script. Please use EVAL.'
        SCRIPT_SHAS.delete(file_name)
        call(file_name, redis_pool, options)
        raise
      else
        raise ScriptError,
              "#{file_name}.lua\n\n#{ex.message}\n\n#{script_source(file_name)}" \
              "#{ex.backtrace.join("\n")}"
      end
    end

    def script_source(file_name)
      script_path(file_name).read
    end

    def script_path(file_name)
      LUA_PATHNAME.join("#{file_name}.lua")
    end
  end
end
