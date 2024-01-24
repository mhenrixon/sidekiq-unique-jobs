# frozen_string_literal: true

require "sidekiq_unique_jobs/script/template"
require "sidekiq_unique_jobs/script/lua_error"
require "sidekiq_unique_jobs/script/script"
require "sidekiq_unique_jobs/script/scripts"
require "sidekiq_unique_jobs/script/config"
require "sidekiq_unique_jobs/script/timing"
require "sidekiq_unique_jobs/script/logging"
require "sidekiq_unique_jobs/script/dsl"
require "sidekiq_unique_jobs/script/client"

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Script
    include SidekiqUniqueJobs::Script::DSL

    configure do |config|
      config.scripts_path = Pathname.new(__FILE__).dirname.join("lua")
      config.logger       = Sidekiq.logger # TODO: This becomes a little weird
    end

    #
    # The current logger
    #
    #
    # @return [Logger] the configured logger
    #
    def self.logger
      config.logger
    end

    #
    # Set a new logger
    #
    # @param [Logger] other another logger
    #
    # @return [Logger] the new logger
    #
    def self.logger=(other)
      config.logger = other
    end
  end
end
