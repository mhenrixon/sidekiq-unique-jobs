require 'pathname'
require 'digest/sha1'

module SidekiqUniqueJobs
  class ScriptError < StandardError
    def initialize(file_name, script_source)
      @message = "There was an error in #{file_name}.lua"
      @script_source = script_source
    end

    def to_s
      "#{@message} \n\n" \
      "Source: #{@script_source}"
    end
  end

  module Scripts
    extend Forwardable
    LUA_PATHNAME ||= Pathname.new(__FILE__).dirname.join('../../redis').freeze
    SOURCE_FILES ||= Dir[LUA_PATHNAME.join('**/*.lua')].compact.freeze
    DEFINED_METHODS ||= []

    module_function

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
    rescue Redis::CommandError
      raise ScriptError.new(file_name, script_source(file_name))
    end

    def connection(redis_pool, &_block)
      SidekiqUniqueJobs.connection(redis_pool) do |conn|
        yield conn
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
