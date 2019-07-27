# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    module Matchers
      class HaveValidSidekiqOptions
        attr_reader :expected_worker, :expected_options

        def initialize(worker, expected_options = {})
          @expected_worker  = worker
          @expected_options = expected_options
        end

        def matches?(controller)
          @controller_class = controller.class
          @actual_resource = @controller_class.instance_variable_get("@aegis_permissions_resource")
          @actual_options = @controller_class.instance_variable_get("@aegis_permissions_options")
          @actual_resource == @worker && @actual_options == @expected_options
        end

        def failure_message
          if @actual_resource != @worker
            "expected #{@controller_class} to check permissions against resource #{@worker.inspect}, but it checked against #{@actual_resource.inspect}"
          else
            "expected #{@controller_class} to check permissions with options #{@expected_options.inspect}, but options were #{@actual_options.inspect}"
          end
        end

        def negative_failure_message
          if @actual_resource == @worker
            "expected #{@controller_class} to not check permissions against resource #{@worker.inspect}"
          else
            "expected #{@controller_class} to not check permissions with options #{@expected_options.inspect}"
          end
        end

        def description
          description = "check permissions against resource #{@worker.inspect}"
          description << " with options #{@expected_options.inspect}" if @expected_options.any?
          description
        end
      end

      def have_valid_sidekiq_options(*args)
        HaveValidSidekiqOptions.new(*args)
      end
    end
  end
end
