# frozen_string_literal: true

require 'timeout'

module SidekiqUniqueJobs
  module Timeout
    def using_timeout(value)
      ::Timeout.timeout(value) do
        yield
      end
    end
  end
end

require 'sidekiq_unique_jobs/timeout/calculator'
