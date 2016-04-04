require 'pathname'
require 'digest/sha1'

module SidekiqUniqueJobs
  ScriptError = Class.new(StandardError)

  module Scripts
    LUA_PATHNAME ||= Pathname.new(__FILE__).dirname.join('../../redis').freeze
    SOURCE_FILES ||= Dir[LUA_PATHNAME.join('**/*.lua')].compact.freeze
    DEFINED_METHODS ||= [].freeze

    module_function

    extend SingleForwardable
    def_delegator :SidekiqUniqueJobs, :connection

    def script_shas
      @script_shas ||= {}
    end

    def logger
      Sidekiq.logger
    end

    def call(file_name, redis_pool, options = {})
      connection(redis_pool) do |redis|
        script_shas[file_name] ||= redis.script(:load, script_source(file_name))
        redis.evalsha(script_shas[file_name], options)
      end
    rescue Redis::CommandError => ex
      if ex.message == 'NOSCRIPT No matching script. Please use EVAL.'
        script_shas[file_name] = nil
        call(file_name, redis_pool, options)
      else
        raise ScriptError,
              "#{file_name}.lua\n\n" +
              ex.message + "\n\n" +
              script_source(file_name) +
              ex.backtrace.join("\n")
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
