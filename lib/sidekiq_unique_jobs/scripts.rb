# frozen_string_literal: true

require 'pathname'
require 'digest/sha1'
require 'concurrent/map'

module SidekiqUniqueJobs
  module Scripts
    LUA_PATHNAME ||= Pathname.new(__FILE__).dirname.join('../../redis').freeze
    SCRIPT_SHAS ||= Concurrent::Map.new

    include SidekiqUniqueJobs::Connection

    module_function

    def call(file_name, redis_pool, options = {})
      execute_script(file_name, redis_pool, options)
    rescue Redis::CommandError => ex
      handle_error(ex, file_name) do
        call(file_name, redis_pool, options)
      end
    end

    def execute_script(file_name, redis_pool, options = {})
      redis(redis_pool) do |conn|
        sha = script_sha(conn, file_name)
        conn.evalsha(sha, options)
      end
    end

    def script_sha(conn, file_name)
      if (sha = SCRIPT_SHAS.get(file_name))
        return sha
      end

      sha = conn.script(:load, script_source(file_name))
      SCRIPT_SHAS.put(file_name, sha)
      sha
    end

    def handle_error(ex, file_name)
      if ex.message == 'NOSCRIPT No matching script. Please use EVAL.'
        SCRIPT_SHAS.delete(file_name)
        return yield if block_given?
      end

      raise ScriptError, file_name: file_name, source_exception: ex
    end

    def script_source(file_name)
      script_path(file_name).read
    end

    def script_path(file_name)
      LUA_PATHNAME.join("#{file_name}.lua")
    end
  end
end
