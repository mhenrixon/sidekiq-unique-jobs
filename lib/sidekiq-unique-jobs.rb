require 'sidekiq-unique-jobs/middleware'
require "sidekiq-unique-jobs/version"
require "sidekiq-unique-jobs/config"
require "sidekiq-unique-jobs/payload_helper"

module SidekiqUniqueJobs
  def self.config
    SidekiqUniqueJobs::Config
  end
end