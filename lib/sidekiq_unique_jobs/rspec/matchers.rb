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

require_relative "matchers/be_lockable"
