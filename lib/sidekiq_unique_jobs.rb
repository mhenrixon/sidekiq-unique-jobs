require 'yaml' if RUBY_VERSION.include?('2.0.0')
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/config'
require 'sidekiq_unique_jobs/payload_helper'

module SidekiqUniqueJobs
  def self.config
    SidekiqUniqueJobs::Config
  end
end
