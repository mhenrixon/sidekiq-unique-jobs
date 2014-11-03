# rubocop:disable FileName
require 'yaml' if RUBY_VERSION.include?('2.0.0')
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/config'
require 'sidekiq_unique_jobs/payload_helper'
require 'ostruct'

module SidekiqUniqueJobs
  module_function

  def config
    @config ||= Config.new(
      unique_prefix: 'sidekiq_unique',
      unique_args_enabled: false,
      default_expiration: 30 * 60,
      default_unlock_order: :after_yield
    )
  end

  def unique_args_enabled?
    config.unique_args_enabled
  end

  def configure
    yield configuration
  end
end
