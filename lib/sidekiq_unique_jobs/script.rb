# frozen_string_literal: true

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Script
    include Brpoplpush::RedisScript::DSL

    configure do |config|
      config.scripts_path = Pathname.new(__FILE__).dirname.join("lua")
      config.logger       = Sidekiq.logger # TODO: This becomes a little weird
    end
  end
end
