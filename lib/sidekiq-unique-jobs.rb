# frozen_string_literal: true

require "sidekiq_unique_jobs"

SidekiqUniqueJobs::Middleware.configure

Sidekiq.options[:lifecycle_events][:unique_lock]    = []
Sidekiq.options[:lifecycle_events][:unique_unlock]  = []
Sidekiq.options[:lifecycle_events][:unique_timeout] = []
