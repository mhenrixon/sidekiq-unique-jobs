# rubocop:disable FileName
require 'yaml' if RUBY_VERSION.include?('2.0.0')
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/config'
require 'sidekiq_unique_jobs/payload_helper'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

require 'ostruct'

module SidekiqUniqueJobs
  module_function

  def config
    @config ||= Config.new(
      unique_prefix: 'sidekiq_unique',
      unique_args_enabled: false,
      default_expiration: 30 * 60,
      default_unlock_order: :after_yield,
      unique_storage_method: :new
    )
  end

  def unique_args_enabled?
    config.unique_args_enabled
  end

  def configure
    yield config
  end

  # Attempt to constantize a string worker_class argument, always
  # failing back to the original argument.
  def worker_class_constantize(worker_class)
    return worker_class unless worker_class.is_a?(String)
    worker_class.constantize
  rescue NameError
    worker_class
  end
end
