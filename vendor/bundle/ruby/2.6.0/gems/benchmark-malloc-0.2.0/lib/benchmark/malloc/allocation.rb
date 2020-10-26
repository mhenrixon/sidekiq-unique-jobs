# frozen_string_literal: true

require "objspace"

module Benchmark
  class Malloc
    class Allocation
      include Comparable

      # The allocated object
      attr_reader :object

      # The allocated object memory size
      attr_reader :memsize

      attr_reader :class_path

      attr_reader :source_file

      attr_reader :source_line

      attr_reader :method_id

      def initialize(object)
        @object      = object
        @memsize     = ObjectSpace.memsize_of(object)
        @class_path  = ObjectSpace.allocation_class_path(object)
        @source_file = ObjectSpace.allocation_sourcefile(object)
        @source_line = ObjectSpace.allocation_sourceline(object)
        @method_id   = ObjectSpace.allocation_method_id(object)
      end

      def extract(*attributes)
        attributes.map do |attr|
          if @object.respond_to?(attr)
            @object.public_send(attr)
          else
            public_send(attr)
          end
        end
      end

      def <=>(other)
        @object <=> other.object &&
          @memsize <=> other.memsize
      end
    end # Allocation
  end # Malloc
end # Benchmark
