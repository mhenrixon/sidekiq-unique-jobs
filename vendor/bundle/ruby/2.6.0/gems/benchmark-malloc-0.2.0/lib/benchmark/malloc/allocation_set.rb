# frozen_string_literal: true

module Benchmark
  class Malloc
    class AllocationSet
      include Enumerable

      attr_reader :allocations

      def initialize(allocations)
        @allocations = allocations
      end

      def each(&block)
        return to_enum(:each) unless block
        @allocations.each(&block)
      end

      # @api public
      def total_objects
        @allocations.size
      end

      # @api public
      def total_memory
        @allocations.reduce(0) { |acc, alloc| acc + alloc.memsize }
      end

      # @api public
      def count_objects
        @allocations.
          map { |alloc| alloc.object.class }.
          each_with_object(Hash.new(0)) { |name, h| h[name] += 1 }
      end

      # @api public
      def count_memory
        @allocations.
          map { |alloc| [alloc.object.class, alloc.memsize] }.
          each_with_object(Hash.new(0)) { |(name, mem), h| h[name] += mem }
      end

      def filter(*class_names)
        @allocations.
          select { |alloc| class_names.include?(alloc.object.class) }
      end
    end # AllocationSet
  end # Malloc
end # Benchmark
