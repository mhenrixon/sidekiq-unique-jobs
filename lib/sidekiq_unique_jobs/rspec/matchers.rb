# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    #
    # Module Matchers provides RSpec matcher for your workers
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    module Matchers
    end
  end
end

require_relative "matchers/have_valid_sidekiq_options"

RSpec.configure do |config|
  config.include SidekiqUniqueJobs::RSpec::Matchers
end
