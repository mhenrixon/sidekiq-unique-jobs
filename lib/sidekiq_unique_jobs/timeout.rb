# frozen_string_literal: true

module SidekiqUniqueJobs
  module Timeout
  end
end

require 'sidekiq_unique_jobs/timeout/calculator'
require 'sidekiq_unique_jobs/timeout/queue_lock'
