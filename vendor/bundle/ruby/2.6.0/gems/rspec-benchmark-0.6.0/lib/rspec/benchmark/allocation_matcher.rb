# frozen_string_literal: true

require "benchmark-malloc"

module RSpec
  module Benchmark
    module AllocationMatcher
      # Implements the `perform_allocation` matcher
      #
      # @api private
      class Matcher
        def initialize(objects, **options)
          @objects = objects
          @retained_objects = nil
          @warmup = options.fetch(:warmup) { 1 }
          @bench  = ::Benchmark::Malloc
          @count_type = :objects
        end

        # Indicates this matcher matches against a block
        #
        # @return [True]
        #
        # @api private
        def supports_block_expectations?
          true
        end

        # @return [Boolean]
        #
        # @api private
        def matches?(block)
          @block = block
          alloc_stats = @bench.trace(&block)
          @actual = nil
          @actual_retained = nil

          case @objects
          when Hash
            case @count_type
            when :memory
              @actual = alloc_stats.allocated.count_memory
            else
              @actual = alloc_stats.allocated.count_objects
            end
            @objects.all? do |name, count|
              @actual[name] <= count
            end
          when Numeric
            case @count_type
            when :memory
              @actual = alloc_stats.allocated.total_memory
              @actual_retained = alloc_stats.retained.total_memory
            else
              @actual = alloc_stats.allocated.total_objects
              @actual_retained = alloc_stats.retained.total_objects
            end
            result = @actual <= @objects
            result &= @actual_retained <= @retained_objects if @retained_objects
            result
          else
            raise ArgumentError, "'#{@objects}' is not a recognized argument"
          end
        end

        def and_retain(objects)
          @retained_objects = objects
          self
        end

        # The time before measurements are taken
        #
        # @param [Numeric] value
        #   the time before measurements are taken
        #
        # @api public
        def warmup(value)
          @warmup = value
          self
        end

        def objects
          @count_type = :objects
          self
        end
        alias object objects

        def memory
          @count_type = :memory
          self
        end
        alias bytes memory

        def failure_message
          "expected block to #{description}, but #{positive_failure_reason}"
        end

        def failure_message_when_negated
          "expected block not to #{description}, but #{negative_failure_reason}"
        end

        def description
          desc = ["perform allocation of #{count_objects(@objects)}"]
          if @retained_objects
            desc << " and retain #{count_objects(@retained_objects)}"
          end
          desc.join
        end

        def count_objects(objects)
          if @count_type == :memory
            "#{objects_to_s(objects)} #{objects == 1 ? "byte" : "bytes"}"
          else
            "#{objects_to_s(objects)} #{pluralize_objects(objects)}"
          end
        end

        def positive_failure_reason
          return "was not a block" unless @block.is_a?(Proc)
          "allocated #{actual}"
        end

        def negative_failure_reason
          "allocated #{actual}"
        end

        def actual
          if @count_type == :memory
            "#{objects_to_s(@actual)} bytes"
          else
            desc = ["#{objects_to_s(@actual)} #{pluralize_objects(@actual)}"]
            if @retained_objects
              desc << " and retained #{objects_to_s(@actual_retained)}"
            end
            desc.join
          end
        end

        def pluralize_objects(value)
          if value.respond_to?(:to_hash)
            if value.keys.size == 1 && value.values.reduce(&:+) == 1
              "object"
            else
              "objects"
            end
          else
            value == 1 ? "object" : "objects"
          end
        end

        def objects_to_s(value)
          if value.respond_to?(:to_hash)
            value
              .sort_by { |k, v| k.to_s }
              .map { |key, val| "#{val} #{key}" if @objects.keys.include?(key) }
              .compact.join(" and ")
          else
            value
          end
        end
      end
    end # AllocationMatcher
  end # Benchmark
end # RSpec
