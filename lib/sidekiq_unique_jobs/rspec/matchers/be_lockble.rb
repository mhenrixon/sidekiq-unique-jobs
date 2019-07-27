# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    module Matchers
      class BeLockable
        attr_reader :expected_worker, :expected_options

        def initialize(worker, expected_options = {})
        end

        def matches?(_worker)
        end

        def failure_message
        end

        def negative_failure_message
        end

        def description
          description = "check options against #{@worker.inspect}"
          description << " with options #{@expected_options.inspect}" if @expected_options.any?
          description
        end
      end

      def be_lockable(*args)
        BeLockable.new(*args)
      end
    end
  end
end
