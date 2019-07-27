# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    #
    # Module Matchers provides RSpec matcher for your workers
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    module Matchers
      #
      # Class BeLockable validates the unique/lock configuration for your worker.
      #
      # @author Mikael Henriksson <mikael@zoolutions.se>
      #
      class BeLockable
        attr_reader :expected_worker, :expected_options

        def initialize(_worker, _expected_options = {}); end

        def matches?(_worker); end

        def failure_message; end

        def negative_failure_message; end

        def description; end
      end

      def be_lockable(*args)
        BeLockable.new(*args)
      end
    end
  end
end
