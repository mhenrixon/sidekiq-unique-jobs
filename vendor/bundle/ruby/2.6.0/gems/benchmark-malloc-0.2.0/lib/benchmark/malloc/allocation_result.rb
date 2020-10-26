# frozen_string_literal: true

module Benchmark
  class Malloc
    class AllocationResult
      attr_reader :allocated

      attr_reader :retained

      def initialize(allocated, retained)
        @allocated = allocated
        @retained = retained
      end

      def total_allocated_objects
        @allocated.total_objects
      end

      def total_retained_objects
        @retained.total_objects
      end
    end # AllocationResult
  end # Malloc
end # Benchmark
