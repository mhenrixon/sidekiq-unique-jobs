# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    module Matchers
      def have_valid_sidekiq_options(*args)
        HaveValidSidekiqOptions.new(*args)
      end
    end
  end
end
