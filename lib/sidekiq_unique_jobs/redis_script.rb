# frozen_string_literal: true

require "sidekiq_unique_jobs/redis_script/template"
require "sidekiq_unique_jobs/redis_script/lua_error"
require "sidekiq_unique_jobs/redis_script/script"
require "sidekiq_unique_jobs/redis_script/scripts"
require "sidekiq_unique_jobs/redis_script/config"
require "sidekiq_unique_jobs/redis_script/timing"
require "sidekiq_unique_jobs/redis_script/logging"
require "sidekiq_unique_jobs/redis_script/dsl"
require "sidekiq_unique_jobs/redis_script/client"

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module RedisScript
    module_function

    include SidekiqUniqueJobs::RedisScript::DSL

    #
    # The current logger
    #
    #
    # @return [Logger] the configured logger
    #
    def logger
      config.logger
    end

    #
    # Set a new logger
    #
    # @param [Logger] other another logger
    #
    # @return [Logger] the new logger
    #
    def logger=(other)
      config.logger = other
    end

    #
    # Execute the given script_name
    #
    #
    # @param [Symbol] script_name the name of the lua script
    # @param [Array<String>] keys script keys
    # @param [Array<Object>] argv script arguments
    # @param [Redis] conn the redis connection to use
    #
    # @return value from script
    #
    def execute(script_name, conn, keys: [], argv: [])
      Client.execute(script_name, conn, keys: keys, argv: argv)
    end
  end
end
